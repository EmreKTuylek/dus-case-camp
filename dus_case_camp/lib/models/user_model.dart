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
    );
  }
}
