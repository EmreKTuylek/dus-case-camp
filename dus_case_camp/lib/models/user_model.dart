import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { student, teacher, admin }

class UserModel {
  final String id;
  final String fullName;
  final String email;
  final UserRole role;
  final String? school;
  final int? yearOfStudy;
  final int totalPoints;
  final DateTime createdAt;
  final DateTime updatedAt;

  final Map<String, UserSpecialtyStats> specialtyStats;
  final List<String> badges;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.school,
    this.yearOfStudy,
    this.totalPoints = 0,
    required this.createdAt,
    required this.updatedAt,
    this.specialtyStats = const {},
    this.badges = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.student,
      ),
      school: json['school'] as String?,
      yearOfStudy: json['yearOfStudy'] as int?,
      totalPoints: json['totalPoints'] as int? ?? 0,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
      specialtyStats: (json['specialtyStats'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              UserSpecialtyStats.fromJson(value as Map<String, dynamic>),
            ),
          ) ??
          {},
      badges: (json['badges'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'role': role.name,
      'school': school,
      'yearOfStudy': yearOfStudy,
      'totalPoints': totalPoints,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'specialtyStats': specialtyStats.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'badges': badges,
    };
  }

  UserModel copyWith({
    String? fullName,
    String? email,
    UserRole? role,
    String? school,
    int? yearOfStudy,
    int? totalPoints,
    DateTime? updatedAt,
    Map<String, UserSpecialtyStats>? specialtyStats,
    List<String>? badges,
  }) {
    return UserModel(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      school: school ?? this.school,
      yearOfStudy: yearOfStudy ?? this.yearOfStudy,
      totalPoints: totalPoints ?? this.totalPoints,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      specialtyStats: specialtyStats ?? this.specialtyStats,
      badges: badges ?? this.badges,
    );
  }
}

class UserSpecialtyStats {
  final int casesSolved;
  final int xp;

  UserSpecialtyStats({
    this.casesSolved = 0,
    this.xp = 0,
  });

  factory UserSpecialtyStats.fromJson(Map<String, dynamic> json) {
    return UserSpecialtyStats(
      casesSolved: json['casesSolved'] as int? ?? 0,
      xp: json['xp'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'casesSolved': casesSolved,
      'xp': xp,
    };
  }
}
