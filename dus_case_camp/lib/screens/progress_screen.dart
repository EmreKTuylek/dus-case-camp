import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/analytics_model.dart';
import '../providers/auth_provider.dart';
import '../models/dental_specialities.dart';
import '../l10n/app_localizations.dart';

final analyticsProvider = StreamProvider<AnalyticsModel?>((ref) {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) return Stream.value(null);

  // Client-side analytics: Fetch all submissions and compute locally
  return FirebaseFirestore.instance
      .collection('submissions')
      .where('studentId', isEqualTo: user.uid)
      .where('status', isEqualTo: 'scored')
      .snapshots()
      .asyncMap((snapshot) async {
    if (snapshot.docs.isEmpty) return null;

    int totalScore = 0;
    Map<String, int> weeklyPoints = {};
    Map<String, Map<String, dynamic>> specialtyStats = {};
    Map<String, int> activityHeatmap = {};

    final caseIds =
        snapshot.docs.map((doc) => doc.data()['caseId'] as String).toSet();
    final Map<String, Map<String, dynamic>> casesMap = {};

    if (caseIds.isNotEmpty) {
      for (final cid in caseIds) {
        final cDoc =
            await FirebaseFirestore.instance.collection('cases').doc(cid).get();
        if (cDoc.exists) casesMap[cid] = cDoc.data()!;
      }
    }

    for (var doc in snapshot.docs) {
      final sub = doc.data();
      final points = (sub['totalPointsAwarded'] as num?)?.toInt() ?? 0;
      totalScore += points;

      final submittedAt = (sub['submittedAt'] as Timestamp?)?.toDate();
      if (submittedAt != null) {
        final dateKey = submittedAt.toIso8601String().split('T')[0];
        activityHeatmap[dateKey] = (activityHeatmap[dateKey] ?? 0) + 1;
      }

      final caseData = casesMap[sub['caseId']];
      if (caseData != null) {
        final weekId = caseData['weekId'] as String? ?? 'unknown';
        weeklyPoints[weekId] = (weeklyPoints[weekId] ?? 0) + points;

        // Resolve Specialty - Standardize to Key
        String key = caseData['specialtyKey'] as String? ?? '';
        if (key.isEmpty) {
          final oldText = caseData['speciality'] as String? ?? '';
          key = DentalSpecialtyConfig.guessFromText(oldText).name;
        }

        if (!specialtyStats.containsKey(key)) {
          specialtyStats[key] = {'points': 0, 'count': 0};
        }
        specialtyStats[key]!['points'] += points;
        specialtyStats[key]!['count'] += 1;
      }
    }

    final weeklyPerformance = weeklyPoints.entries
        .map((e) => WeeklyPerformance(week: e.key, points: e.value))
        .toList();
    final specialtyPerformance = specialtyStats.entries.map((e) {
      final avg = e.value['points'] / e.value['count'];
      return SpecialtyPerformance(specialty: e.key, average: avg);
    }).toList();

    return AnalyticsModel(
      totalCompletedCases: snapshot.docs.length,
      totalScore: totalScore,
      weeklyPerformance: weeklyPerformance,
      specialtyPerformance: specialtyPerformance,
      activityHeatmap: activityHeatmap,
    );
  });
});

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsProvider);
    final l10n = AppLocalizations.of(context)!;

    // Determine current language code for specialty labels
    final currentLang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.progressTitle)),
      body: analyticsAsync.when(
        data: (data) {
          if (data == null) {
            return Center(child: Text(l10n.noAnalytics));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCards(context, data, l10n),
                const SizedBox(height: 24),
                Text(l10n.weeklyPerformance,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                _buildWeeklyChart(data, l10n),
                const SizedBox(height: 24),
                Text(l10n.specialtyStrengths,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                _buildSpecialtyChart(data, l10n, currentLang),
                const SizedBox(height: 24),
                Text(l10n.activity,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                _buildActivityHeatmap(data, l10n),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildSummaryCards(
      BuildContext context, AnalyticsModel data, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: l10n.statCasesCompleted,
            value: data.totalCompletedCases.toString(),
            icon: Icons.check_circle_outline,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            title: l10n.statTotalScore,
            value: data.totalScore.toString(),
            icon: Icons.emoji_events_outlined,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart(AnalyticsModel data, AppLocalizations l10n) {
    if (data.weeklyPerformance.isEmpty) return Text(l10n.notEnoughData);

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < data.weeklyPerformance.length) {
                    return Text(
                        data.weeklyPerformance[value.toInt()].week
                            .split('_')
                            .last,
                        style: const TextStyle(fontSize: 10));
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: data.weeklyPerformance.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                    toY: e.value.points.toDouble(), color: Colors.blueAccent)
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSpecialtyChart(
      AnalyticsModel data, AppLocalizations l10n, String lang) {
    if (data.specialtyPerformance.isEmpty) return Text(l10n.notEnoughData);

    // Simple bar chart for specialty as Radar chart needed complex configuration in fl_chart 0.60+
    // and layout management. Horizontal bar list is readable.
    return Column(
      children: data.specialtyPerformance.map((e) {
        // e.specialty is the KEY. Convert to Label.
        final label = DentalSpecialtyConfig.getLabel(
            DentalSpecialtyConfig.fromKey(e.specialty),
            lang: lang);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              SizedBox(
                  width: 100,
                  child: Text(label,
                      style: const TextStyle(fontWeight: FontWeight.bold))),
              Expanded(
                child: LinearProgressIndicator(
                  value: e.average / 100, // Assuming 100 is max avg
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation(Colors.green),
                  minHeight: 10,
                ),
              ),
              const SizedBox(width: 16),
              Text('${e.average.toStringAsFixed(1)} avg'),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActivityHeatmap(AnalyticsModel data, AppLocalizations l10n) {
    // Simple summary for now
    final totalActiveDays = data.activityHeatmap.length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.calendar_month, size: 40, color: Colors.purple),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$totalActiveDays ${l10n.activeDays}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18)),
                Text(l10n.keepStreak),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(
      {required this.title,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(value,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
