import 'package:flutter/foundation.dart'; // for kIsWeb, defaultTargetPlatform
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../models/interactive_models.dart';
import '../models/case_model.dart';
import 'dart:async';

class CasePlayer extends StatefulWidget {
  final CaseModel caseModel;
  final Function(Duration) onPositionChanged;
  final Function(InteractiveStep)? onInteractiveStepHit;
  final VoidCallback? onVideoCompleted;
  final VideoPlayerController? existingController;

  const CasePlayer({
    super.key,
    required this.caseModel,
    required this.onPositionChanged,
    this.onInteractiveStepHit,
    this.onVideoCompleted,
    this.existingController,
  });

  @override
  State<CasePlayer> createState() => CasePlayerState();
}

class CasePlayerState extends State<CasePlayer> {
  // Standalone Player (VOD / Live HLS)
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  // YouTube Player
  YoutubePlayerController? _youtubeController;

  Timer? _timer;
  String? _lastHandledStepId;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void didUpdateWidget(CasePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.caseModel.id != widget.caseModel.id ||
        oldWidget.caseModel.videoUrl != widget.caseModel.videoUrl ||
        oldWidget.caseModel.videoType != widget.caseModel.videoType) {
      _disposeControllers();
      _initializePlayer();
    }
  }

  void _disposeControllers() {
    _timer?.cancel();
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _youtubeController?.close();
    _videoPlayerController = null;
    _chewieController = null;
    _youtubeController = null;
    _errorMessage = null;
  }

  Future<void> _initializePlayer() async {
    final isYouTube = widget.caseModel.videoType == CaseVideoType.youtube;
    final url = widget.caseModel.videoType == CaseVideoType.live
        ? widget.caseModel.liveStreamUrl
        : widget.caseModel.videoUrl;

    if (url == null || url.trim().isEmpty) {
      if (mounted) setState(() => _errorMessage = "No video URL provided.");
      return;
    }

    try {
      if (isYouTube) {
        // --- YouTube Initialization ---
        final videoId = _convertUrlToId(url);
        if (videoId == null) {
          if (mounted) setState(() => _errorMessage = "Invalid YouTube URL.");
          return;
        }

        _youtubeController = YoutubePlayerController.fromVideoId(
          videoId: videoId,
          autoPlay: true,
          params: const YoutubePlayerParams(
            showControls: true,
            showFullscreenButton: true,
            mute: false,
            // Fix for "Error 15" (Playback Restriction / Embed Issue)
            strictRelatedVideos: true,
          ),
        );

        // No async init needed for IFrame controller itself, but we should clear error
        if (mounted) setState(() => _errorMessage = null);
      } else {
        // --- Standard/Live Player Initialization ---
        _videoPlayerController =
            VideoPlayerController.networkUrl(Uri.parse(url));
        await _videoPlayerController!.initialize();

        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController!,
          autoPlay: true,
          looping: false,
          isLive: widget.caseModel.videoType == CaseVideoType.live,
          aspectRatio: 16 / 9,
          errorBuilder: (context, errorMessage) {
            return Center(
              child: Text(
                errorMessage,
                style: const TextStyle(color: Colors.white),
              ),
            );
          },
        );

        _videoPlayerController!.addListener(_checkInteractiveStepStd);
      }
    } catch (e) {
      debugPrint("Player Initialization Error: $e");
      if (mounted) setState(() => _errorMessage = "Error loading video: $e");
    }

    // Common Timer for Position & Interactive Steps
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      if (_youtubeController != null) {
        final position = await _youtubeController!.currentTime;
        final duration = await _youtubeController!.duration;

        widget.onPositionChanged(Duration(seconds: position.toInt()));
        _checkInteractiveStepYouTube(position);

        // Check Completion (simple heurstic: > 95% or ended state)
        // Note: YouTube iframe sends 'ended' state events, but polling helps too.
        if (duration > 0 && position >= duration * 0.98) {
          widget.onVideoCompleted?.call();
        }
      } else if (_videoPlayerController != null &&
          _videoPlayerController!.value.isInitialized &&
          _videoPlayerController!.value.isPlaying) {
        final val = _videoPlayerController!.value;
        widget.onPositionChanged(val.position);

        if (val.duration.inMilliseconds > 0 && val.position >= val.duration) {
          // or nearly there
          widget.onVideoCompleted?.call();
        }
      }
    });

    if (mounted) {
      setState(() {});
    }
  }

  String? _convertUrlToId(String url) {
    if (url.trim().isEmpty) return null;

    // 1. Regex for standard/mobile/embed/shorts
    final RegExp regExp = RegExp(
      r'^.*((youtu.be\/)|(v\/)|(\/u\/\w\/)|(embed\/)|(watch\?)|(shorts\/))\??v?=?([^#&?]*).*',
      caseSensitive: false,
      multiLine: false,
    );

    final match = regExp.firstMatch(url);
    if (match != null && match.groupCount >= 8) {
      final id = match.group(8);
      if (id != null && id.isNotEmpty) return id;
    }

    // 2. Direct ID fallback (11 chars)
    if (url.length == 11 && !url.contains('/')) return url;

    return null;
  }

  // --- Logic for Standard Player (VOD/Live) ---
  void _checkInteractiveStepStd() {
    if (_videoPlayerController == null ||
        !_videoPlayerController!.value.isInitialized) return;

    final position = _videoPlayerController!.value.position;

    if (widget.caseModel.interactiveSteps.isNotEmpty &&
        widget.onInteractiveStepHit != null) {
      for (final step in widget.caseModel.interactiveSteps) {
        final diff = (position.inSeconds - step.pauseAtSeconds).abs();

        if (diff <= 1 &&
            _videoPlayerController!.value.isPlaying &&
            _lastHandledStepId != step.id) {
          _videoPlayerController!.pause();
          _lastHandledStepId = step.id;
          widget.onInteractiveStepHit!(step);
          break;
        }
      }
    }
  }

  // --- Logic for YouTube Player ---
  void _checkInteractiveStepYouTube(double currentSeconds) {
    if (widget.caseModel.interactiveSteps.isEmpty ||
        widget.onInteractiveStepHit == null) return;

    for (final step in widget.caseModel.interactiveSteps) {
      final diff = (currentSeconds - step.pauseAtSeconds).abs();

      // Note: We can't easily check isPlaying sync from controller, but if timer loop is updating
      // position and we hit a step we haven't handled, we pause.
      if (diff <= 1 && _lastHandledStepId != step.id) {
        _youtubeController!.pauseVideo();
        _lastHandledStepId = step.id;
        widget.onInteractiveStepHit!(step);
        break;
      }
    }
  }

  void seekTo(Duration position) {
    if (_youtubeController != null) {
      _youtubeController!.seekTo(seconds: position.inSeconds.toDouble());
    } else {
      _videoPlayerController?.seekTo(position);
    }
  }

  void play() {
    if (_youtubeController != null) {
      _youtubeController!.playVideo();
    } else {
      _chewieController?.play();
    }
  }

  void pause() {
    if (_youtubeController != null) {
      _youtubeController!.pauseVideo();
    } else {
      _chewieController?.pause();
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Error State
    if (_errorMessage != null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.black,
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(_errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center),
          ),
        ),
      );
    }

    // 1. YouTube Player (Priority if controller exists)
    if (_youtubeController != null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: YoutubePlayer(
          controller: _youtubeController!,
          aspectRatio: 16 / 9,
        ),
      );
    }

    // 2. YouTube Type but failed info (Fallback)
    if (widget.caseModel.videoType == CaseVideoType.youtube) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(child: CircularProgressIndicator(color: Colors.red)),
      );
    }

    // 2. Live Stream Placeholder (if no URL)
    if (widget.caseModel.videoType == CaseVideoType.live &&
        widget.caseModel.liveStreamUrl == null) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(child: Text('Live Stream not available')),
      );
    }

    // 3. Standard Player (VOD / Live with URL)
    if (_chewieController != null &&
        _chewieController!.videoPlayerController.value.isInitialized) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Chewie(
          controller: _chewieController!,
        ),
      );
    } else {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
  }
}
