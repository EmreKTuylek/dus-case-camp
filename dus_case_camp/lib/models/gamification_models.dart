import 'package:cloud_firestore/cloud_firestore.dart';

// --- Points ---

class PointEvent {
  final String id;
  final String userId;
  final String
      eventType; // prep_read, live_attend, interactive_answer, case_complete
  final String? caseId;
  final int points;
  final DateTime createdAt;

  PointEvent({
    required this.id,
    required this.userId,
    required this.eventType,
    this.caseId,
    required this.points,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'eventType': eventType,
        'caseId': caseId,
        'points': points,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory PointEvent.fromJson(Map<String, dynamic> json) {
    return PointEvent(
      id: json['id'] as String,
      userId: json['userId'] as String,
      eventType: json['eventType'] as String,
      caseId: json['caseId'] as String?,
      points: json['points'] as int,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }
}

// --- Badges ---

class BadgeConfig {
  final String id;
  final String name;
  final String description;
  final String iconPath; // asset path or icon name

  const BadgeConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
  });
}

class UserBadge {
  final String userId;
  final String badgeId;
  final DateTime earnedAt;

  UserBadge({
    required this.userId,
    required this.badgeId,
    required this.earnedAt,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'badgeId': badgeId,
        'earnedAt': Timestamp.fromDate(earnedAt),
      };

  factory UserBadge.fromJson(Map<String, dynamic> json) {
    return UserBadge(
      userId: json['userId'] as String,
      badgeId: json['badgeId'] as String,
      earnedAt: (json['earnedAt'] as Timestamp).toDate(),
    );
  }
}

// --- Certificates ---

class UserCertificate {
  final String id;
  final String userId;
  final String title;
  final String description;
  final DateTime issuedAt;

  UserCertificate({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.issuedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'title': title,
        'description': description,
        'issuedAt': Timestamp.fromDate(issuedAt),
      };

  factory UserCertificate.fromJson(Map<String, dynamic> json) {
    return UserCertificate(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      issuedAt: (json['issuedAt'] as Timestamp).toDate(),
    );
  }
}

// --- Recommendations / Stats ---

class UserSpecialtyStat {
  final String userId;
  final String specialty;
  final int casesSolved;
  final double averageScore;
  final DateTime lastActivity;

  UserSpecialtyStat({
    required this.userId,
    required this.specialty,
    required this.casesSolved,
    required this.averageScore,
    required this.lastActivity,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'specialty': specialty,
        'casesSolved': casesSolved,
        'averageScore': averageScore,
        'lastActivity': Timestamp.fromDate(lastActivity),
      };

  factory UserSpecialtyStat.fromJson(Map<String, dynamic> json) {
    return UserSpecialtyStat(
      userId: json['userId'] as String,
      specialty: json['specialty'] as String,
      casesSolved: json['casesSolved'] as int,
      averageScore: (json['averageScore'] as num).toDouble(),
      lastActivity: (json['lastActivity'] as Timestamp).toDate(),
    );
  }
}
