class LeaderboardEntry {
  final String id;
  final String studentId; // Can be used to fetch user details
  final int totalPoints;
  final int rank;
  final String? weekId; // Null for global leaderboard

  LeaderboardEntry({
    required this.id,
    required this.studentId,
    required this.totalPoints,
    required this.rank,
    this.weekId,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      id: json['id'] as String,
      studentId: json['studentId'] as String,
      totalPoints: json['totalPoints'] as int? ?? 0,
      rank: json['rank'] as int? ?? 0,
      weekId: json['weekId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'totalPoints': totalPoints,
      'rank': rank,
      'weekId': weekId,
    };
  }
}
