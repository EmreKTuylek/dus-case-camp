import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';

import '../../models/case_model.dart';
import '../../models/interactive_models.dart';
import '../../providers/auth_provider.dart';
import '../../models/dental_specialities.dart';

class AdminCaseEditor extends ConsumerStatefulWidget {
  final String weekId;
  final CaseModel? caseModel; // Null if creating new

  const AdminCaseEditor({super.key, required this.weekId, this.caseModel});

  @override
  ConsumerState<AdminCaseEditor> createState() => _AdminCaseEditorState();
}

class _AdminCaseEditorState extends ConsumerState<AdminCaseEditor> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  // late TextEditingController _specialityController; // Removed
  late TextEditingController _videoUrlController;
  late TextEditingController _liveUrlController;

  CaseLevel _level = CaseLevel.medium;
  DentalSpecialty _selectedSpecialty =
      DentalSpecialty.other; // New Dropdown Value

  CaseVideoType _videoType = CaseVideoType.vod;
  DateTime? _liveStart;
  DateTime? _liveEnd;

  List<PrepMaterial> _prepMaterials = [];
  List<InteractiveStep> _interactiveSteps = [];
  List<Chapter> _chapters = [];

  bool _isSaving = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _uploadStatusText = '';

  @override
  void initState() {
    super.initState();
    final c = widget.caseModel;
    _titleController = TextEditingController(text: c?.title ?? '');
    _descController = TextEditingController(text: c?.description ?? '');
    // _specialityController = TextEditingController(text: c?.speciality ?? '');
    _videoUrlController = TextEditingController(text: c?.videoUrl ?? '');
    _liveUrlController = TextEditingController(text: c?.liveStreamUrl ?? '');

    _level = c?.level ?? CaseLevel.medium;
    _videoType = c?.videoType ?? CaseVideoType.vod;
    _liveStart = c?.liveSessionStart;
    _liveEnd = c?.liveSessionEnd;

    // Initialize Specialty
    if (c != null) {
      _selectedSpecialty = DentalSpecialtyConfig.fromKey(c.specialtyKey);
    }

    _prepMaterials = List.from(c?.prepMaterials ?? []);
    _interactiveSteps = List.from(c?.interactiveSteps ?? []);
    _chapters = List.from(c?.chapters ?? []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    // _specialityController.dispose();
    _videoUrlController.dispose();
    _liveUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You must be logged in to upload videos.')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadStatusText = 'Waiting for file selection...';
    });

    try {
      if (kDebugMode) print('Starting video pick...');

      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        withData: true, // Force load bytes for Web
      );

      if (result != null) {
        setState(() => _uploadStatusText = 'Processing file...');
        final file = result.files.first;
        if (kDebugMode)
          print(
              'File picked: ${file.name}, size: ${file.size}, bytes: ${file.bytes?.length}');

        if (kIsWeb && file.size > 50 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'Warning: Large video files (>50MB) may crash on Web due to memory limits. Use smaller clips or native app.')));
        }

        final ref = FirebaseStorage.instance.ref().child(
            'cases/${DateTime.now().millisecondsSinceEpoch}_${file.name}');

        UploadTask task;
        if (kIsWeb) {
          if (file.bytes == null) {
            throw 'File bytes are null. Please try again or use a smaller file.';
          }
          final metadata = SettableMetadata(
              contentType: 'video/mp4'); // Help browser handling
          task = ref.putData(file.bytes!, metadata);
        } else {
          task = ref.putFile(File(file.path!));
        }

        task.snapshotEvents.listen((event) {
          if (mounted) {
            setState(() {
              _uploadProgress = event.bytesTransferred /
                  (event.totalBytes > 0 ? event.totalBytes : 1);
              _uploadStatusText =
                  'Uploading: ${(_uploadProgress * 100).toStringAsFixed(0)}%';
            });
          }
        });

        await task;

        setState(() => _uploadStatusText = 'Getting download URL...');
        final url = await ref.getDownloadURL();
        if (kDebugMode) print('Upload success: $url');

        setState(() {
          _videoUrlController.text = url;
          _uploadStatusText = 'Upload Complete!';
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Video uploaded successfully!')));
        }
      } else {
        if (kDebugMode) print('User canceled picker');
        setState(() {
          _isUploading = false;
          _uploadStatusText = '';
        });
      }
    } catch (e, stack) {
      if (kDebugMode) print('Upload Error: $e\n$stack');
      setState(() => _uploadStatusText = 'Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Upload failed: $e. See console for details.')));
      }
    } finally {
      if (_uploadStatusText.contains('Error') || _uploadStatusText.isEmpty) {
        if (mounted) setState(() => _isUploading = false);
      } else {
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _saveCase() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final user = ref.read(firebaseAuthProvider).currentUser;
      if (user == null) throw 'Not authenticated';

      final id = widget.caseModel?.id ??
          'case_${DateTime.now().millisecondsSinceEpoch}';

      final newCase = CaseModel(
        id: id,
        weekId: widget.weekId,
        title: _titleController.text,
        description: _descController.text,
        specialtyKey: _selectedSpecialty.name, // Use Enum Key
        level: _level,
        mediaUrls: widget.caseModel?.mediaUrls ?? [],
        createdBy: widget.caseModel?.createdBy ?? user.uid,
        createdAt: widget.caseModel?.createdAt ?? DateTime.now(),
        videoType: _videoType,
        videoUrl:
            _videoUrlController.text.isEmpty ? null : _videoUrlController.text,
        liveStreamUrl:
            _liveUrlController.text.isEmpty ? null : _liveUrlController.text,
        liveSessionStart: _liveStart,
        liveSessionEnd: _liveEnd,
        chapters: _chapters,
        prepMaterials: _prepMaterials,
        interactiveSteps: _interactiveSteps,
      );

      // ... (Rest of save unchanged) ...
      await FirebaseFirestore.instance
          .collection('cases')
          .doc(id)
          .set(newCase.toJson());

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Case saved successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error saving: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // --- UI Builders ---

  Widget _buildBasicInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => v!.isEmpty ? 'Required' : null),
            const SizedBox(height: 8),
            TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<DentalSpecialty>(
                    value: _selectedSpecialty,
                    decoration: const InputDecoration(labelText: 'Specialty'),
                    items: DentalSpecialty.values.map((s) {
                      return DropdownMenuItem(
                          value: s,
                          child: Text(
                              DentalSpecialtyConfig.getLabel(s, lang: 'tr')));
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedSpecialty = v!),
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<CaseLevel>(
                  value: _level,
                  items: CaseLevel.values
                      .map((l) => DropdownMenuItem(
                          value: l, child: Text(l.name.toUpperCase())))
                      .toList(),
                  onChanged: (v) => setState(() => _level = v!),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoConfig() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Video Configuration',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            DropdownButtonFormField<CaseVideoType>(
              value: _videoType,
              decoration: const InputDecoration(labelText: 'Case Type'),
              items: CaseVideoType.values
                  .map((t) => DropdownMenuItem(
                      value: t, child: Text(t.name.toUpperCase())))
                  .toList(),
              onChanged: (v) => setState(() => _videoType = v!),
            ),
            const SizedBox(height: 16),
            if (_videoType == CaseVideoType.youtube) ...[
              TextFormField(
                  controller: _videoUrlController,
                  decoration: const InputDecoration(
                      labelText: 'YouTube Video URL',
                      hintText: 'https://youtube.com/watch?v=...')),
            ],
            if (_videoType == CaseVideoType.vod ||
                _videoType == CaseVideoType.vodWithLiveQa) ...[
              Row(
                children: [
                  Expanded(
                      child: TextFormField(
                          controller: _videoUrlController,
                          decoration: const InputDecoration(
                              labelText: 'VOD URL (.mp4)'))),
                  IconButton(
                      onPressed: _pickVideo,
                      icon: const Icon(Icons.upload_file)),
                ],
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() => _videoUrlController.text =
                      'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4');
                },
                icon: const Icon(Icons.science),
                label: const Text('Use Sample Video (Debug)'),
              ),
              if (_isUploading) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(value: _uploadProgress),
                const SizedBox(height: 4),
                Text(_uploadStatusText,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ],
            if (_videoType == CaseVideoType.live ||
                _videoType == CaseVideoType.vodWithLiveQa) ...[
              const SizedBox(height: 16),
              TextFormField(
                  controller: _liveUrlController,
                  decoration:
                      const InputDecoration(labelText: 'Live Stream URL')),
              const SizedBox(height: 8),
              ListTile(
                title: Text(_liveStart == null
                    ? 'Set Start Time'
                    : 'Start: ${DateFormat('MM/dd HH:mm').format(_liveStart!)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2030));
                  if (date != null && mounted) {
                    final time = await showTimePicker(
                        context: context, initialTime: TimeOfDay.now());
                    if (time != null) {
                      setState(() => _liveStart = DateTime(date.year,
                          date.month, date.day, time.hour, time.minute));
                    }
                  }
                },
              ),
              ListTile(
                title: Text(_liveEnd == null
                    ? 'Set End Time'
                    : 'End: ${DateFormat('MM/dd HH:mm').format(_liveEnd!)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  // Similar logic for End time
                  final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2030));
                  if (date != null && mounted) {
                    final time = await showTimePicker(
                        context: context, initialTime: TimeOfDay.now());
                    if (time != null) {
                      setState(() => _liveEnd = DateTime(date.year, date.month,
                          date.day, time.hour, time.minute));
                    }
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveSteps() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('AI Interactive Questions',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _showStepDialog()),
              ],
            ),
            const Text('Strict Mode: AI will only use provided keywords.',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _interactiveSteps.length,
              itemBuilder: (context, index) {
                final step = _interactiveSteps[index];
                return ListTile(
                  leading: CircleAvatar(child: Text('${step.pauseAtSeconds}s')),
                  title: Text(step.questionText),
                  subtitle: Text('Req: ${step.requiredKeywords.join(", ")}'),
                  trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() => _interactiveSteps.removeAt(index));
                      }),
                  onTap: () => _showStepDialog(step: step, index: index),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showStepDialog({InteractiveStep? step, int? index}) {
    final pauseController =
        TextEditingController(text: step?.pauseAtSeconds.toString() ?? '0');
    final qController = TextEditingController(text: step?.questionText ?? '');
    final aController =
        TextEditingController(text: step?.correctAnswerText ?? '');
    final reqController =
        TextEditingController(text: step?.requiredKeywords.join(', ') ?? '');
    final bonusController =
        TextEditingController(text: step?.bonusKeywords.join(', ') ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(step == null ? 'Add AI Step' : 'Edit AI Step'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: pauseController,
                  decoration:
                      const InputDecoration(labelText: 'Pause at (seconds)'),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: qController,
                  decoration: const InputDecoration(labelText: 'Question')),
              TextField(
                  controller: aController,
                  decoration: const InputDecoration(
                      labelText: 'Correct Answer (Reference)')),
              TextField(
                  controller: reqController,
                  decoration: const InputDecoration(
                      labelText: 'Required Keywords (comma sep)')),
              TextField(
                  controller: bonusController,
                  decoration: const InputDecoration(
                      labelText: 'Bonus Keywords (comma sep)')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newStep = InteractiveStep(
                id: step?.id ??
                    DateTime.now().millisecondsSinceEpoch.toString(),
                pauseAtSeconds: int.tryParse(pauseController.text) ?? 0,
                questionText: qController.text,
                correctAnswerText: aController.text,
                requiredKeywords: reqController.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList(),
                bonusKeywords: bonusController.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList(),
              );
              setState(() {
                if (index != null) {
                  _interactiveSteps[index] = newStep;
                } else {
                  _interactiveSteps.add(newStep);
                }
                // Sort by timestamp
                _interactiveSteps.sort(
                    (a, b) => a.pauseAtSeconds.compareTo(b.pauseAtSeconds));
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.caseModel == null ? 'Create Case' : 'Edit Case')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildBasicInfo(),
              const SizedBox(height: 16),
              _buildVideoConfig(),
              const SizedBox(height: 16),
              _buildInteractiveSteps(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveCase,
                  icon: const Icon(Icons.save),
                  label: Text(_isSaving ? 'Saving...' : 'Save Case'),
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
