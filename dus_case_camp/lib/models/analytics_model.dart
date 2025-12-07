class AnalyticsModel {
  final int totalCompletedCases;
  final int totalScore;
  final List<WeeklyPerformance> weeklyPerformance;
  final List<SpecialtyPerformance> specialtyPerformance;
  final Map<String, int> activityHeatmap;

  AnalyticsModel({
    required this.totalCompletedCases,
    required this.totalScore,
    this.weeklyPerformance = const [],
    this.specialtyPerformance = const [],
    this.activityHeatmap = const {},
  });

  factory AnalyticsModel.fromJson(Map<String, dynamic> json) {
    return AnalyticsModel(
      totalCompletedCases: json['totalCompletedCases'] as int? ?? 0,
      totalScore: json['totalScore'] as int? ?? 0,
      weeklyPerformance: (json['weeklyPerformance'] as List<dynamic>?)
              ?.map((e) => WeeklyPerformance.fromJson(e))
              .toList() ??
          [],
      specialtyPerformance: (json['specialtyPerformance'] as List<dynamic>?)
              ?.map((e) => SpecialtyPerformance.fromJson(e))
              .toList() ??
          [],
      activityHeatmap: Map<String, int>.from(json['activityHeatmap'] ?? {}),
    );
  }
}

class WeeklyPerformance {
  final String week;
  final int points;

  WeeklyPerformance({required this.week, required this.points});

  factory WeeklyPerformance.fromJson(Map<String, dynamic> json) {
    return WeeklyPerformance(
      week: json['week'] as String? ?? '',
      points: json['points'] as int? ?? 0,
    );
  }
}

class SpecialtyPerformance {
  final String specialty;
  final double average;

  SpecialtyPerformance({required this.specialty, required this.average});

  factory SpecialtyPerformance.fromJson(Map<String, dynamic> json) {
    return SpecialtyPerformance(
      specialty: json['specialty'] as String? ?? 'Unknown',
      average: (json['average'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
