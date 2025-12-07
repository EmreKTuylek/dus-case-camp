import 'dart:io';
import 'dart:typed_data';
import '../utils/error_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../models/case_model.dart';
import '../models/submission_model.dart';
import '../widgets/adaptive_video_player.dart';
import '../widgets/comment_section.dart';
import 'package:url_launcher/url_launcher.dart';

// New Imports
import '../widgets/case_player.dart';
import '../widgets/chapter_list.dart';
import '../widgets/live_chat_panel.dart';
import '../models/interactive_models.dart';
import '../services/ai_evaluation_service.dart';

class CaseDetailScreen extends ConsumerStatefulWidget {
  final String caseId;

  const CaseDetailScreen({super.key, required this.caseId});

  @override
  ConsumerState<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends ConsumerState<CaseDetailScreen> {
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _selectedType = 'video'; // video, text, photo
  final _textAnswerController = TextEditingController();
  List<XFile> _selectedPhotos = [];

  // Player State
  Duration _currentPosition = Duration.zero;
  final GlobalKey<CasePlayerState> _playerKey = GlobalKey<CasePlayerState>();

  bool _isChatActive(CaseModel caseModel) {
    if (caseModel.videoType == CaseVideoType.vod) return false;

    // For LIVE or VOD_WITH_LIVE_QA
    final now = DateTime.now();
    if (caseModel.liveSessionStart != null &&
        caseModel.liveSessionEnd != null) {
      return now.isAfter(caseModel.liveSessionStart!) &&
          now.isBefore(caseModel.liveSessionEnd!);
    }

    // Fallback: If it's pure LIVE logic without times, allow if type is live.
    if (caseModel.videoType == CaseVideoType.live) return true;

    return false;
  }

  void _onChapterTap(int seconds) {
    _playerKey.currentState?.seekTo(Duration(seconds: seconds));
  }

  Future<void> _submitAnswer() async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      String? videoUrl;
      String? textAnswer;
      List<String> photoUrls = [];

      // 1. Handle Video
      if (_selectedType == 'video') {
        dynamic file;
        Uint8List? fileBytes;

        if (kIsWeb) {
          final result =
              await FilePicker.platform.pickFiles(type: FileType.video);
          if (result != null) {
            fileBytes = result.files.first.bytes;
          }
        } else {
          final picker = ImagePicker();
          final pickedFile =
              await picker.pickVideo(source: ImageSource.gallery);
          if (pickedFile != null) {
            file = File(pickedFile.path);
          }
        }

        if ((kIsWeb && fileBytes == null) || (!kIsWeb && file == null)) {
          setState(() => _isUploading = false);
          return;
        }

        final storageRef = FirebaseStorage.instance
            .ref()
            .child('submissions/${widget.caseId}/${user.uid}_video.mp4');

        UploadTask task;
        if (kIsWeb) {
          task = storageRef.putData(fileBytes!);
        } else {
          task = storageRef.putFile(file);
        }

        task.snapshotEvents.listen((event) {
          setState(() {
            _uploadProgress = event.bytesTransferred / event.totalBytes;
          });
        });

        await task;
        videoUrl = await storageRef.getDownloadURL();
      }

      // 2. Handle Text
      else if (_selectedType == 'text') {
        if (_textAnswerController.text.trim().isEmpty) {
          throw 'Please enter your answer.';
        }
        textAnswer = _textAnswerController.text.trim();
      }

      // 3. Handle Photos
      else if (_selectedType == 'photo') {
        if (_selectedPhotos.isEmpty) {
          throw 'Please select at least one photo.';
        }

        for (int i = 0; i < _selectedPhotos.length; i++) {
          final photo = _selectedPhotos[i];
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('submissions/${widget.caseId}/${user.uid}_photo_$i.jpg');

          if (kIsWeb) {
            final bytes = await photo.readAsBytes();
            await storageRef.putData(bytes);
          } else {
            await storageRef.putFile(File(photo.path));
          }
          photoUrls.add(await storageRef.getDownloadURL());
        }
      }

      // Create submission record
      final submission = SubmissionModel(
        id: '${widget.caseId}_${user.uid}',
        caseId: widget.caseId,
        studentId: user.uid,
        videoUrl: videoUrl,
        textAnswer: textAnswer,
        photoUrls: photoUrls,
        submittedAt: DateTime.now(),
        status: SubmissionStatus.pending_review,
      );

      await FirebaseFirestore.instance
          .collection('submissions')
          .doc(submission.id)
          .set(submission.toJson());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Answer submitted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, e);
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _pickPhotos() async {
    final picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedPhotos = images;
      });
    }
  }

  Widget _buildFeedbackSection(String title, String? content) {
    if (content == null || content.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text(content, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

// ... existing imports

  void _handleInteractiveStep(InteractiveStep step) async {
    // 1. Pause is already handled by CasePlayer

    // 2. Show Modal
    final answer = await showDialog<InteractiveAnswer>(
      context: context,
      barrierDismissible: false, // Force answer
      builder: (context) => _InteractiveQuestionDialog(
        step: step,
        caseId: widget.caseId,
        studentId: ref.read(firebaseAuthProvider).currentUser!.uid,
      ),
    );

    // 3. Save to Firestore (fire and forget or await)
    if (answer != null) {
      FirebaseFirestore.instance
          .collection('interactive_answers')
          .doc(answer.id)
          .set(answer.toJson());

      // 4. Resume video
      // Skip past the pause point (1.5s) to avoid immediate re-trigger
      _playerKey.currentState?.seekTo(
          Duration(milliseconds: (step.pauseAtSeconds * 1000 + 1500).toInt()));
      _playerKey.currentState?.play();
    }
  }

  Widget _buildUnifiedPlayer(BuildContext context, CaseModel caseModel) {
    String? effectiveVideoUrl = caseModel.videoUrl;

    // ... (fallback logic same as before) ...
    if (effectiveVideoUrl == null && caseModel.videoType == CaseVideoType.vod) {
      final videoMedia = caseModel.mediaUrls.firstWhere(
        (url) => url.toLowerCase().contains('.mp4'),
        orElse: () => '',
      );
      if (videoMedia.isNotEmpty) {
        effectiveVideoUrl = videoMedia;
      }
    }

    if ((caseModel.videoType == CaseVideoType.vod &&
            effectiveVideoUrl == null) ||
        (caseModel.videoType == CaseVideoType.live &&
            caseModel.liveStreamUrl == null) ||
        (caseModel.videoType == CaseVideoType.vodWithLiveQa &&
            effectiveVideoUrl == null)) {
      return const SizedBox.shrink();
    }

    // ... (temp model creation same as before update loop) ...
    final playerCaseModel = CaseModel(
      id: caseModel.id,
      weekId: caseModel.weekId,
      title: caseModel.title,
      description: caseModel.description,
      specialtyKey: caseModel.specialtyKey, // Updated field
      level: caseModel.level,
      mediaUrls: caseModel.mediaUrls,
      createdBy: caseModel.createdBy,
      createdAt: caseModel.createdAt,
      teaser: caseModel.teaser,
      preparationMaterials: caseModel.preparationMaterials,
      videoType: caseModel.videoType,
      videoUrl: effectiveVideoUrl,
      liveStreamUrl: caseModel.liveStreamUrl,
      liveSessionStart: caseModel.liveSessionStart,
      liveSessionEnd: caseModel.liveSessionEnd,
      chapters: caseModel.chapters,
      interactiveSteps: caseModel.interactiveSteps, // Pass steps!
    );

    final showChat = caseModel.videoType != CaseVideoType.vod;
    final isLargeScreen = MediaQuery.of(context).size.width > 900;

    Widget playerSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CasePlayer(
          key: _playerKey,
          caseModel: playerCaseModel,
          onPositionChanged: (pos) {
            setState(() => _currentPosition = pos);
          },
          onInteractiveStepHit: _handleInteractiveStep, // Hook callback
        ),
// ... rest of method ...

        if (caseModel.chapters.isNotEmpty)
          ChapterList(
            chapters: caseModel.chapters,
            onChapterTap: _onChapterTap,
          ),
      ],
    );

    if (!showChat) return playerSection;

    Widget chatSection = Card(
      elevation: 2,
      child: SizedBox(
        height: 500, // Fixed height for chat
        child: LiveChatPanel(
          caseId: caseModel.id,
          isChatActive: _isChatActive(caseModel),
        ),
      ),
    );

    if (isLargeScreen) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: playerSection),
          const SizedBox(width: 16),
          Expanded(flex: 1, child: chatSection),
        ],
      );
    } else {
      return Column(
        children: [
          playerSection,
          const SizedBox(height: 16),
          chatSection,
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(firebaseAuthProvider).currentUser;
    final caseAsync = ref.watch(caseProvider(widget.caseId));
    final submissionAsync = ref.watch(submissionProvider(widget.caseId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Case Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showScoringRules(context),
          ),
        ],
      ),
      body: caseAsync.when(
        data: (caseModel) {
          if (caseModel == null)
            return const Center(child: Text('Case not found'));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUnifiedPlayer(context, caseModel),
                const SizedBox(height: 24),
                Text(caseModel.title,
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Chip(label: Text(caseModel.speciality)),
                    const SizedBox(width: 8),
                    Chip(label: Text(caseModel.level.name.toUpperCase())),
                  ],
                ),
                const SizedBox(height: 16),
                Text(caseModel.description,
                    style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 24),

                // Show other materials if existing
                if (caseModel.mediaUrls.isNotEmpty) ...[
                  const Divider(),
                  const SizedBox(height: 16),
                  Text('Case Materials',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  ...caseModel.mediaUrls.map((url) {
                    final name = url.split('/').last.split('?').first;
                    final isVideo = name.toLowerCase().endsWith('.mp4');
                    final isImage = name.toLowerCase().endsWith('.jpg') ||
                        name.toLowerCase().endsWith('.png');

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          isVideo
                              ? Icons.videocam
                              : (isImage ? Icons.image : Icons.picture_as_pdf),
                          color: Theme.of(context).primaryColor,
                        ),
                        title: Text(name),
                        trailing: const Icon(Icons.open_in_new),
                        onTap: () => _launchMedia(url),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],
                const Divider(),
                const SizedBox(height: 16),
                Text('Your Answer',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                submissionAsync.when(
                  data: (submission) {
                    if (submission != null) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Icon(Icons.check_circle,
                                  color: Colors.green, size: 48),
                              const SizedBox(height: 8),
                              const SizedBox(height: 8),
                              if (submission.videoUrl != null)
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: AdaptiveVideoPlayer(
                                    originalUrl: submission.videoUrl!,
                                    videoUrls: submission.transcodedPaths?.map(
                                            (k, v) =>
                                                MapEntry(k, v.toString())) ??
                                        {},
                                  ),
                                )
                              else
                                Text(submission.textAnswer != null
                                    ? 'Text Answer Submitted'
                                    : 'Photos Submitted'),
                              const SizedBox(height: 8),
                              Text(
                                  'Status: ${submission.status.name.toUpperCase()}'),
                              if (submission.teacherScore != null)
                                Text('Score: ${submission.teacherScore}/100',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                              if (submission.teacherFeedback != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                      'Feedback: ${submission.teacherFeedback}'),
                                ),
                              if (submission.aiStatus == 'completed' &&
                                  submission.autoFeedback != null) ...[
                                const SizedBox(height: 16),
                                const Divider(),
                                Theme(
                                  data: Theme.of(context).copyWith(
                                      dividerColor: Colors.transparent),
                                  child: ExpansionTile(
                                    leading: const Icon(Icons.auto_awesome,
                                        color: Colors.purple),
                                    title: const Text('AI Coach Feedback',
                                        style: TextStyle(
                                            color: Colors.purple,
                                            fontWeight: FontWeight.bold)),
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _buildFeedbackSection(
                                                'Summary',
                                                submission
                                                    .autoFeedback!['summary']
                                                    ?.toString()),
                                            _buildFeedbackSection(
                                                'Missing Points',
                                                (submission.autoFeedback![
                                                            'missing_points']
                                                        as List?)
                                                    ?.map((e) => '• $e')
                                                    .join('\n')),
                                            _buildFeedbackSection(
                                                'Reasoning',
                                                submission
                                                    .autoFeedback!['reasoning']
                                                    ?.toString()),
                                            _buildFeedbackSection(
                                                'Advice',
                                                submission
                                                    .autoFeedback!['advice']
                                                    ?.toString()),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else if (submission.aiStatus == 'error') ...[
                                const SizedBox(height: 12),
                                const Text('Automatic feedback unavailable.',
                                    style: TextStyle(
                                        color: Colors.grey,
                                        fontStyle: FontStyle.italic,
                                        fontSize: 12)),
                              ],
                            ],
                          ),
                        ),
                      );
                    } else {
                      return Center(
                        child: _isUploading
                            ? Column(
                                children: [
                                  CircularProgressIndicator(
                                      value: _uploadProgress),
                                  const SizedBox(height: 8),
                                  Text(
                                      'Uploading: ${(_uploadProgress * 100).toStringAsFixed(0)}%'),
                                ],
                              )
                            : Column(
                                children: [
                                  SegmentedButton<String>(
                                    segments: const [
                                      ButtonSegment(
                                          value: 'video',
                                          label: Text('Video'),
                                          icon: Icon(Icons.videocam)),
                                      ButtonSegment(
                                          value: 'text',
                                          label: Text('Text'),
                                          icon: Icon(Icons.text_fields)),
                                      ButtonSegment(
                                          value: 'photo',
                                          label: Text('Photo'),
                                          icon: Icon(Icons.photo)),
                                    ],
                                    selected: {_selectedType},
                                    onSelectionChanged:
                                        (Set<String> newSelection) {
                                      setState(() {
                                        _selectedType = newSelection.first;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  if (_selectedType == 'text')
                                    TextField(
                                      controller: _textAnswerController,
                                      maxLines: 5,
                                      decoration: const InputDecoration(
                                        hintText: 'Type your answer here...',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  if (_selectedType == 'photo')
                                    Column(
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: _pickPhotos,
                                          icon: const Icon(Icons.add_a_photo),
                                          label: const Text('Select Photos'),
                                        ),
                                        if (_selectedPhotos.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                                '${_selectedPhotos.length} photos selected'),
                                          ),
                                      ],
                                    ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: _submitAnswer,
                                    icon: const Icon(Icons.send),
                                    label: const Text('Submit Answer'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 32, vertical: 16),
                                    ),
                                  ),
                                ],
                              ),
                      );
                    }
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Text('Error loading submission: $e'),
                ),
                const SizedBox(height: 24),
                const Divider(thickness: 1),
                CommentSection(caseId: widget.caseId),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _launchMedia(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Could not open file')));
    }
  }

  void _showScoringRules(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How Points Work'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('• Base Points: +10 for submitting.'),
              SizedBox(height: 8),
              Text('• Early Bird: +10 (24h) or +5 (48h).'),
              SizedBox(height: 8),
              Text('• Teacher Score: Up to +50 points (Score * 0.5).'),
              SizedBox(height: 16),
              Text('Total Max: ~70 points per case.',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it')),
        ],
      ),
    );
  }
}

class _InteractiveQuestionDialog extends StatefulWidget {
  final InteractiveStep step;
  final String caseId;
  final String studentId;

  const _InteractiveQuestionDialog({
    required this.step,
    required this.caseId,
    required this.studentId,
  });

  @override
  State<_InteractiveQuestionDialog> createState() =>
      _InteractiveQuestionDialogState();
}

class _InteractiveQuestionDialogState
    extends State<_InteractiveQuestionDialog> {
  final _controller = TextEditingController();
  InteractiveAnswer? _result;

  void _submit() {
    if (_controller.text.trim().isEmpty) return;

    final evaluation = AiEvaluationService.evaluateAnswer(
      step: widget.step,
      studentAnswer: _controller.text.trim(),
      studentId: widget.studentId,
      caseId: widget.caseId,
    );

    setState(() {
      _result = evaluation;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Interactive Question'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.step.questionText,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            if (_result == null)
              TextField(
                controller: _controller,
                maxLines: 4,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Type your answer here...',
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Your Answer: ${_result!.answerText}'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('AI Score: ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${_result!.aiScore?.toStringAsFixed(0)}/100',
                          style: TextStyle(
                            color: (_result!.aiScore ?? 0) >= 70
                                ? Colors.green
                                : Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          )),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Feedback:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(_result!.aiFeedback ?? 'No feedback provided.'),
                ],
              ),
          ],
        ),
      ),
      actions: [
        if (_result == null)
          ElevatedButton(
            onPressed: _submit,
            child: const Text('Submit Answer'),
          )
        else
          TextButton(
            onPressed: () => Navigator.pop(context, _result),
            child: const Text('Continue Video'),
          ),
      ],
    );
  }
} // End of file

final caseProvider = FutureProvider.family<CaseModel?, String>((ref, id) async {
  final doc =
      await FirebaseFirestore.instance.collection('cases').doc(id).get();
  if (doc.exists) return CaseModel.fromJson(doc.data()!);
  return null;
});

final submissionProvider =
    StreamProvider.family<SubmissionModel?, String>((ref, caseId) {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('submissions')
      .doc('${caseId}_${user.uid}')
      .snapshots()
      .map((doc) => doc.exists ? SubmissionModel.fromJson(doc.data()!) : null);
});
