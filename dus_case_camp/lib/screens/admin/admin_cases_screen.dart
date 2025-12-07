import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:typed_data';

import '../../models/case_model.dart';

import 'admin_case_editor.dart';

class AdminCasesScreen extends ConsumerWidget {
  final String weekId;

  const AdminCasesScreen({super.key, required this.weekId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final casesAsync = ref.watch(casesForWeekAdminProvider(weekId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Cases'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openEditor(context),
          ),
        ],
      ),
      body: casesAsync.when(
        data: (cases) {
          if (cases.isEmpty)
            return const Center(child: Text('No cases in this week.'));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cases.length,
            itemBuilder: (context, index) {
              final c = cases[index];
              return Card(
                child: ListTile(
                  title: Text(c.title),
                  subtitle:
                      Text('${c.speciality} • ${c.level.name.toUpperCase()}'),
                  onTap: () => _openEditor(context, caseModel: c),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        tooltip: 'Edit Case',
                        onPressed: () => _openEditor(context, caseModel: c),
                      ),
                      IconButton(
                        icon:
                            const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _deleteCase(context, c.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _openEditor(BuildContext context, {CaseModel? caseModel}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminCaseEditor(weekId: weekId, caseModel: caseModel),
      ),
    );
  }

  Future<void> _deleteCase(BuildContext context, String caseId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Case?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('cases').doc(caseId).delete();
    }
  }
}

class _MediaManagerDialog extends StatefulWidget {
  final String caseId;
  final List<String> initialUrls;

  const _MediaManagerDialog({required this.caseId, required this.initialUrls});

  @override
  State<_MediaManagerDialog> createState() => _MediaManagerDialogState();
}

class _MediaManagerDialogState extends State<_MediaManagerDialog> {
  late List<String> _urls;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _urls = List.from(widget.initialUrls);
  }

  Future<void> _pickAndUpload() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'mp4', 'jpg', 'png'],
      );

      if (result != null) {
        setState(() => _isUploading = true);

        Uint8List? fileBytes;
        String fileName = result.files.first.name;

        if (kIsWeb) {
          fileBytes = result.files.first.bytes;
        } else {
          fileBytes = await File(result.files.first.path!).readAsBytes();
        }

        if (fileBytes != null) {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('cases/${widget.caseId}/$fileName');

          await storageRef.putData(fileBytes);
          final url = await storageRef.getDownloadURL();

          setState(() {
            _urls.add(url);
          });
          await FirebaseFirestore.instance
              .collection('cases')
              .doc(widget.caseId)
              .update({'mediaUrls': _urls});
        }
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteUrl(String url) async {
    setState(() {
      _urls.remove(url);
    });
    await FirebaseFirestore.instance
        .collection('cases')
        .doc(widget.caseId)
        .update({'mediaUrls': _urls});
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Manage Media'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_urls.isEmpty) const Text('No media uploaded.'),
            ..._urls.map((url) => ListTile(
                  title: Text(url.split('/').last.split('?').first,
                      overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteUrl(url),
                  ),
                )),
            if (_isUploading)
              const Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close')),
        ElevatedButton.icon(
          onPressed: _isUploading ? null : _pickAndUpload,
          icon: const Icon(Icons.upload_file),
          label: const Text('Upload File'),
        ),
      ],
    );
  }
}

final casesForWeekAdminProvider =
    StreamProvider.family<List<CaseModel>, String>((ref, weekId) {
  return FirebaseFirestore.instance
      .collection('cases')
      .where('weekId', isEqualTo: weekId)
      .snapshots()
      .map((s) => s.docs.map((d) => CaseModel.fromJson(d.data())).toList());
});
