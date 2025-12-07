import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/gamification_models.dart';
import '../models/leaderboard_model.dart';
import '../models/dental_specialities.dart';

class GamificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Constants ---
  static const int POINTS_READ_PREP = 10;
  static const int POINTS_LIVE_ATTEND = 50;
  static const int POINTS_INTERACTIVE_ANSWER = 20;
  static const int POINTS_CASE_COMPLETE = 100;

  // --- Point System ---

  Future<void> awardPoints({
    required String userId,
    required String eventType, // e.g. 'prep_read'
    required int points,
    String? caseId,
  }) async {
    final eventRef = _firestore.collection('userPointsEvents').doc();
    final userRef = _firestore.collection('users').doc(userId);

    // Run as transaction to ensure totalPoints is updated atomically
    try {
      await _firestore.runTransaction((transaction) async {
        final userSnapshot = await transaction.get(userRef);
        if (!userSnapshot.exists) return;

        // 1. Create Event
        final event = PointEvent(
          id: eventRef.id,
          userId: userId,
          eventType: eventType,
          caseId: caseId,
          points: points,
          createdAt: DateTime.now(),
        );
        transaction.set(eventRef, event.toJson());

        // 2. Update User Total
        int currentTotal =
            (userSnapshot.data() as Map<String, dynamic>)['totalPoints'] ?? 0;
        transaction.update(userRef, {'totalPoints': currentTotal + points});

        // 3. (Optional) Update Leaderboards - ideally done via Cloud Functions,
        // but for client-side demo we might skip or do a lightweight update if needed.
        // We will rely on the UI simply reading the user's total for Global.
      });
      debugPrint("Awarded $points points to $userId for $eventType");

      // Trigger Badge Check (Client-side simulation)
      checkBadges(userId);
    } catch (e) {
      debugPrint("Error awarding points: $e");
    }
  }

  // --- Badge System ---

  // Hardcoded Badges for now
  static const List<BadgeConfig> AVAILABLE_BADGES = [
    BadgeConfig(
      id: 'first_step',
      name: 'First Step',
      description: 'Awarded for earning your first point.',
      iconPath: 'assets/badges/starter.png',
    ),
    BadgeConfig(
      id: 'dedicated_student',
      name: 'Dedicated',
      description: 'Earned 500 XP.',
      iconPath: 'assets/badges/advanced.png',
    ),
    // Specialty Badges
    BadgeConfig(
      id: 'endo_starter',
      name: 'Endo Starter',
      description: 'Solved 1 Endodontics Case.',
      iconPath: 'assets/badges/endo_starter.png',
    ),
    BadgeConfig(
      id: 'endo_master',
      name: 'Endo Master',
      description: 'Solved 5 Endodontics Cases.',
      iconPath: 'assets/badges/endo_master.png',
    ),
    // Add others systematically as needed
  ];

  Future<void> checkBadges(String userId) async {
    // Simple client-side check example
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final totalPoints = (userDoc.data()?['totalPoints'] ?? 0) as int;

      if (totalPoints > 0) {
        await _grantBadge(userId, 'first_step');
      }
      if (totalPoints >= 500) {
        await _grantBadge(userId, 'dedicated_student');
      }

      // --- Specialty Badge Check ---
      // Fetch user's scored submissions
      final subsSnapshot = await _firestore
          .collection('submissions')
          .where('studentId', isEqualTo: userId)
          .where('status', isEqualTo: 'scored')
          .get();

      if (subsSnapshot.docs.isNotEmpty) {
        final caseIds =
            subsSnapshot.docs.map((d) => d.data()['caseId'] as String).toSet();

        final Map<String, int> specialtyCounts = {};

        // Fetch cases to check specialty
        for (final cid in caseIds) {
          final cDoc = await _firestore.collection('cases').doc(cid).get();
          if (cDoc.exists) {
            final data = cDoc.data()!;

            // ROBUST RESOLUTION:
            String rawVal = data['specialtyKey'] as String? ?? '';
            if (rawVal.isEmpty) {
              rawVal = data['speciality'] as String? ?? '';
            }

            // Normalize using Config
            final normalizedKey =
                DentalSpecialtyConfig.guessFromText(rawVal).name;
            debugPrint(
                "Case $cid: raw='$rawVal' -> normalized='$normalizedKey'");

            specialtyCounts[normalizedKey] =
                (specialtyCounts[normalizedKey] ?? 0) + 1;
          }
        }

        // Grant Specialty Badges
        // Endodontics
        final endoCount = specialtyCounts['endodontics'] ?? 0;
        if (endoCount >= 1) await _grantBadge(userId, 'endo_starter');
        if (endoCount >= 5) await _grantBadge(userId, 'endo_master');

        // Example for others
        final orthoCount = specialtyCounts['orthodontics'] ?? 0;
        if (orthoCount >= 1) await _grantBadge(userId, 'ortho_starter');
      }
    } catch (e) {
      debugPrint("Badge check error: $e");
    }
  }

  Future<void> _grantBadge(String userId, String badgeId) async {
    final badgeRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('userBadges')
        .doc(badgeId);

    final snapshot = await badgeRef.get();
    if (!snapshot.exists) {
      await badgeRef.set(UserBadge(
        userId: userId,
        badgeId: badgeId,
        earnedAt: DateTime.now(),
      ).toJson());
      debugPrint("Granted badge $badgeId to $userId");
    }
  }

  Stream<List<UserBadge>> getUserBadges(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('userBadges')
        .orderBy('earnedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => UserBadge.fromJson(d.data())).toList());
  }

  Stream<List<UserCertificate>> getUserCertificates(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('userCertificates')
        .orderBy('issuedAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => UserCertificate.fromJson(d.data())).toList());
  }

  // --- Leaderboards ---
  // Using the new 'leaderboards' collection structure or mimicking logic
  Stream<List<LeaderboardEntry>> getLeaderboard(
      {required String type, required String periodId}) {
    // For this MVP, we might just query users sorted by totalPoints for Global
    if (type == 'global') {
      return _firestore
          .collection('users')
          .orderBy('totalPoints', descending: true)
          .limit(50)
          .snapshots()
          .map((s) {
        int rank = 1;
        return s.docs.map((d) {
          final data = d.data();
          return LeaderboardEntry(
            id: d.id,
            studentId: d.id,
            totalPoints: data['totalPoints'] ?? 0,
            rank: rank++,
          );
        }).toList();
      });
    }

    // For Weekly/Monthly, we would query strict collections.
    // Returning empty for now if not populated.
    return _firestore
        .collection('leaderboards')
        .where('type', isEqualTo: type)
        .where('periodKey', isEqualTo: periodId)
        .snapshots()
        .map((s) {
      if (s.docs.isEmpty) return [];
      // Assuming entries are in a subcollection or array.
      // Implementing as a direct query for simplicity if collections existed.
      return [];
    });
  }
}
