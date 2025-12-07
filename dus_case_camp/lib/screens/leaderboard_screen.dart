import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/leaderboard_model.dart';
import '../providers/auth_provider.dart';
import '../services/gamification_service.dart' as import_gamification_service;
import '../l10n/app_localizations.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.leaderboardTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.tabWeekly),
              Tab(text: l10n.tabMonthly),
              Tab(text: l10n.tabAllTime),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            LeaderboardList(scope: 'weekly'),
            LeaderboardList(scope: 'monthly'),
            LeaderboardList(scope: 'global'),
          ],
        ),
      ),
    );
  }
}

class LeaderboardList extends ConsumerWidget {
  final String scope; // weekly, monthly, global

  const LeaderboardList({super.key, required this.scope});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Current period calculation for demo (e.g. 2025-12)
    final now = DateTime.now();
    final currentMonthKey =
        "${now.year}-${now.month.toString().padLeft(2, '0')}";
    // Simple week key logic or just pass 'current'
    final periodKey = scope == 'global'
        ? null
        : (scope == 'monthly' ? currentMonthKey : 'current_week');

    final leaderboardAsync =
        ref.watch(leaderboardProvider((scope: scope, period: periodKey)));
    final currentUser = ref.watch(firebaseAuthProvider).currentUser;
    final l10n = AppLocalizations.of(context)!;

    return leaderboardAsync.when(
      data: (entries) {
        if (entries.isEmpty) return Center(child: Text(l10n.noRankings));
        return ListView.builder(
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            final isMe = entry.studentId == currentUser?.uid;
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: isMe ? Colors.blue : Colors.grey[300],
                child: Text(
                  '#${entry.rank}',
                  style: TextStyle(color: isMe ? Colors.white : Colors.black),
                ),
              ),
              title: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(entry.studentId)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    return Text(data['fullName'] ?? l10n.unknownStudent,
                        style: TextStyle(
                            fontWeight:
                                isMe ? FontWeight.bold : FontWeight.normal));
                  }
                  return const Text('Loading...');
                },
              ),
              trailing: Text('${entry.totalPoints} pts'),
              tileColor: isMe ? Colors.blue.withOpacity(0.1) : null,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }
}

// Updated Provider Signature
typedef LeaderboardParams = ({String scope, String? period});

final leaderboardProvider =
    StreamProvider.family<List<LeaderboardEntry>, LeaderboardParams>(
        (ref, params) {
  final service = ref.watch(gamificationServiceProvider);
  return service.getLeaderboard(
      type: params.scope, periodId: params.period ?? '');
});

// Provider for service
final gamificationServiceProvider =
    Provider((ref) => import_gamification_service.GamificationService());
