import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  final String id;
  final String caseId;
  final String senderId;
  final String senderName;
  final String messageText;
  final DateTime createdAt;
  final bool isDeleted;

  ChatMessageModel({
    required this.id,
    required this.caseId,
    required this.senderId,
    required this.senderName,
    required this.messageText,
    required this.createdAt,
    this.isDeleted = false,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      caseId: json['caseId'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      messageText: json['messageText'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caseId': caseId,
      'senderId': senderId,
      'senderName': senderName,
      'messageText': messageText,
      'createdAt': Timestamp.fromDate(createdAt),
      'isDeleted': isDeleted,
    };
  }
}
