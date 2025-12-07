import 'package:cloud_firestore/cloud_firestore.dart';

class WeekModel {
  final String id;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final int caseCount;

  WeekModel({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    this.isActive = false,
    this.caseCount = 0,
  });

  factory WeekModel.fromJson(Map<String, dynamic> json) {
    return WeekModel(
      id: json['id'] as String,
      title: json['title'] as String,
      startDate: (json['startDate'] as Timestamp).toDate(),
      endDate: (json['endDate'] as Timestamp).toDate(),
      isActive: json['isActive'] as bool? ?? false,
      caseCount: json['caseCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'isActive': isActive,
      'caseCount': caseCount,
    };
  }
}
