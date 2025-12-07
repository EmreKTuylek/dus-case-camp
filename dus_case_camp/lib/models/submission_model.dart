import 'package:cloud_firestore/cloud_firestore.dart';

enum SubmissionStatus { pending_review, scored, rejected }

class SubmissionModel {
  final String id;
  final String caseId;
  final String studentId;
  final String? videoUrl; // Made nullable
  final String? textAnswer;
  final List<String> photoUrls;
  final int? durationSeconds;
  final DateTime submittedAt;
  final SubmissionStatus status;
  final int? teacherScore;
  final String? teacherFeedback;
  final int totalPointsAwarded;
  final Map<String, dynamic>? autoFeedback;
  final String? aiStatus;
  final String? transcodingStatus;
  final List<String>? transcodedSizes;
  final Map<String, dynamic>? transcodedPaths;
  final int? originalSize;

  SubmissionModel({
    required this.id,
    required this.caseId,
    required this.studentId,
    this.videoUrl,
    this.textAnswer,
    this.photoUrls = const [],
    this.durationSeconds,
    required this.submittedAt,
    this.status = SubmissionStatus.pending_review,
    this.teacherScore,
    this.teacherFeedback,
    this.totalPointsAwarded = 0,
    this.autoFeedback,
    this.aiStatus,
    this.transcodingStatus,
    this.transcodedSizes,
    this.transcodedPaths,
    this.originalSize,
  });

  factory SubmissionModel.fromJson(Map<String, dynamic> json) {
    return SubmissionModel(
      id: json['id'] as String? ?? '',
      caseId: json['caseId'] as String? ?? '',
      studentId: json['studentId'] as String? ?? '',
      videoUrl: json['videoUrl'] as String?,
      textAnswer: json['textAnswer'] as String?,
      photoUrls: (json['photoUrls'] as List<dynamic>?)
              ?.where((e) => e != null)
              .map((e) => e.toString())
              .toList() ??
          [],
      durationSeconds: json['durationSeconds'] as int?,
      submittedAt: json['submittedAt'] is Timestamp
          ? (json['submittedAt'] as Timestamp).toDate()
          : DateTime.now(), // Fallback to now if missing
      status: SubmissionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SubmissionStatus.pending_review,
      ),
      teacherScore: json['teacherScore'] as int?,
      teacherFeedback: json['teacherFeedback'] as String?,
      totalPointsAwarded: json['totalPointsAwarded'] as int? ?? 0,
      autoFeedback: json['autoFeedback'] as Map<String, dynamic>?,
      aiStatus: json['aiStatus'] as String?,
      transcodingStatus: json['transcodingStatus'] as String?,
      transcodedSizes: (json['transcodedSizes'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      transcodedPaths: json['transcodedPaths'] as Map<String, dynamic>?,
      originalSize: json['originalSize'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caseId': caseId,
      'studentId': studentId,
      'videoUrl': videoUrl,
      'textAnswer': textAnswer,
      'photoUrls': photoUrls,
      'durationSeconds': durationSeconds,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'status': status.name,
      'teacherScore': teacherScore,
      'teacherFeedback': teacherFeedback,
      'totalPointsAwarded': totalPointsAwarded,
      'autoFeedback': autoFeedback,
      'aiStatus': aiStatus,
      'transcodingStatus': transcodingStatus,
      'transcodedSizes': transcodedSizes,
      'transcodedPaths': transcodedPaths,
      'originalSize': originalSize,
    };
  }
}
