import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/week_model.dart';
import '../../providers/auth_provider.dart';

class AdminWeeksScreen extends ConsumerWidget {
  const AdminWeeksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeksAsync = ref.watch(allWeeksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Weeks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddWeekDialog(context),
          ),
        ],
      ),
      body: weeksAsync.when(
        data: (weeks) {
          if (weeks.isEmpty) return const Center(child: Text('No weeks created yet.'));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: weeks.length,
            itemBuilder: (context, index) {
              final week = weeks[index];
              return Card(
                child: ListTile(
                  title: Text(week.title),
                  subtitle: Text(
                    '${DateFormat('MMM d').format(week.startDate)} - ${DateFormat('MMM d').format(week.endDate)}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (week.isActive)
                        const Chip(label: Text('Active'), backgroundColor: Colors.greenAccent)
                      else
                        TextButton(
                          onPressed: () => _activateWeek(context, week.id),
                          child: const Text('Activate'),
                        ),
                      IconButton(
                        icon: const Icon(Icons.edit_note),
                        onPressed: () => context.go('/admin/weeks/${week.id}/cases'),
                        tooltip: 'Manage Cases',
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

  Future<void> _activateWeek(BuildContext context, String weekId) async {
    try {
      // Deactivate all weeks first (batch update ideally, but simple for now)
      final batch = FirebaseFirestore.instance.batch();
      final weeks = await FirebaseFirestore.instance.collection('weeks').get();
      for (var doc in weeks.docs) {
        batch.update(doc.reference, {'isActive': false});
      }
      // Activate selected
      batch.update(FirebaseFirestore.instance.collection('weeks').doc(weekId), {'isActive': true});
      await batch.commit();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Week activated')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showAddWeekDialog(BuildContext context) {
    final titleController = TextEditingController();
    DateTimeRange? dateRange;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Week'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title (e.g. Week 3)'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2023),
                  lastDate: DateTime(2026),
                );
                if (picked != null) {
                  dateRange = picked;
                }
              },
              child: const Text('Select Dates'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty && dateRange != null) {
                final id = 'week_${DateTime.now().millisecondsSinceEpoch}';
                final week = WeekModel(
                  id: id,
                  title: titleController.text,
                  startDate: dateRange!.start,
                  endDate: dateRange!.end,
                  isActive: false,
                );
                await FirebaseFirestore.instance.collection('weeks').doc(id).set(week.toJson());
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

final allWeeksProvider = StreamProvider<List<WeekModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('weeks')
      .orderBy('startDate', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => WeekModel.fromJson(d.data())).toList());
});
