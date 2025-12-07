import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  FirebaseMessaging? _messaging;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> initialize() async {
    try {
      _messaging = FirebaseMessaging.instance;
    } catch (e) {
      if (kDebugMode) print('Firebase Messaging not available: $e');
      return;
    }

    // 1. Request Permission
    NotificationSettings settings = await _messaging!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) {
        print('User granted permission');
      }

      // 2. Get Token & Save
      String? token = await _messaging!.getToken();
      if (token != null) {
        await _saveTokenToDatabase(token);
      }

      // 3. Listen for Token Refresh
      _messaging!.onTokenRefresh.listen(_saveTokenToDatabase);

      // 4. Subscribe to Topics (default: new_weeks)
      await _messaging!.subscribeToTopic('new_weeks');
    } else {
      if (kDebugMode) {
        print('User declined or has not accepted permission');
      }
    }
  }

  Future<void> _saveTokenToDatabase(String token) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
      }, SetOptions(merge: true));
    }
  }

  // Handle foreground messages if needed
  void setupForegroundHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');
      }

      if (message.notification != null) {
        if (kDebugMode) {
          print(
              'Message also contained a notification: ${message.notification}');
        }
        // Show a local notification or snackbar here if desired
      }
    });
  }
}
