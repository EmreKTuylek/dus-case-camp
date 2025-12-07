import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class AdaptiveVideoPlayer extends StatefulWidget {
  final Map<String, String> videoUrls; // e.g., {'1080p': 'url', '720p': 'url'}
  final String originalUrl;
  final bool autoPlay;

  const AdaptiveVideoPlayer({
    super.key,
    required this.videoUrls,
    required this.originalUrl,
    this.autoPlay = false,
  });

  @override
  State<AdaptiveVideoPlayer> createState() => _AdaptiveVideoPlayerState();
}

class _AdaptiveVideoPlayerState extends State<AdaptiveVideoPlayer> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  String? _currentQuality;
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer([String? quality]) async {
    final urls = widget.videoUrls;
    // Default to 480p or 720p if available, else original
    String targetUrl = widget.originalUrl;
    String targetQuality = quality ?? 'Original';

    if (quality == null) {
      if (urls.containsKey('720p')) {
        targetUrl = urls['720p']!;
        targetQuality = '720p';
      } else if (urls.containsKey('480p')) {
        targetUrl = urls['480p']!;
        targetQuality = '480p';
      } else if (urls.isNotEmpty) {
        targetUrl = urls.values.first;
        targetQuality = urls.keys.first;
      }
    } else {
      if (quality == 'Original') {
        targetUrl = widget.originalUrl;
      } else {
        targetUrl = urls[quality] ?? widget.originalUrl;
      }
    }

    _currentQuality = targetQuality;

    // Dispose old controller if exists (when switching quality)
    if (_isInit) {
      final oldController = _videoPlayerController;
      await oldController.pause();
      // We don't dispose immediately to avoid UI flicker if possible, but standard flow is dispose.
      _chewieController?.dispose();
      await oldController.dispose();
    }

    _videoPlayerController =
        VideoPlayerController.networkUrl(Uri.parse(targetUrl));

    await _videoPlayerController.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: widget.autoPlay,
      looping: false,
      aspectRatio: _videoPlayerController.value.aspectRatio,
      additionalOptions: (context) {
        return <OptionItem>[
          OptionItem(
            onTap: (context) {
              Navigator.of(context).pop();
              _showQualitySelector(context);
            },
            iconData: Icons.settings,
            title: 'Quality: $_currentQuality',
          ),
        ];
      },
      errorBuilder: (context, errorMessage) {
        return Center(
          child: Text(
            'Error: $errorMessage',
            style: const TextStyle(color: Colors.white),
          ),
        );
      },
    );

    if (mounted) {
      setState(() {
        _isInit = true;
      });
    }
  }

  void _showQualitySelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final options = ['Original', ...widget.videoUrls.keys];
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: options.map((q) {
                return ListTile(
                  title: Text(q),
                  trailing:
                      q == _currentQuality ? const Icon(Icons.check) : null,
                  onTap: () {
                    Navigator.pop(context);
                    if (q != _currentQuality) {
                      _initializePlayer(q);
                    }
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInit || _chewieController == null) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return AspectRatio(
      aspectRatio: _videoPlayerController.value.aspectRatio,
      child: Chewie(controller: _chewieController!),
    );
  }
}
