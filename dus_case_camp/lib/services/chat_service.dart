import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> sendMessage(String caseId, String message) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Fetch user profile to get the name (or store name in user model locally)
    // For now, assume displayName is set or use email
    String senderName = user.displayName ?? user.email?.split('@')[0] ?? 'User';

    // Refinement: Ideally fetch from users collection if displayName is empty
    if (user.displayName == null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        senderName = userDoc.data()?['fullName'] ?? senderName;
      }
    }

    final docRef = _firestore.collection('caseLiveChatMessages').doc();
    final chatMessage = ChatMessageModel(
      id: docRef.id,
      caseId: caseId,
      senderId: user.uid,
      senderName: senderName,
      messageText: message,
      createdAt: DateTime.now(),
    );

    await docRef.set(chatMessage.toJson());
  }

  Stream<List<ChatMessageModel>> getMessagesStream(String caseId) {
    return _firestore
        .collection('caseLiveChatMessages')
        .where('caseId', isEqualTo: caseId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessageModel.fromJson(doc.data()))
            .toList());
  }

  Future<void> deleteMessage(String messageId) async {
    // Only set isDeleted flag or actual delete
    await _firestore.collection('caseLiveChatMessages').doc(messageId).update({
      'isDeleted': true,
    });
  }
}
