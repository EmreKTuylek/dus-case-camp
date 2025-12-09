import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/gamification_models.dart';
import '../models/leaderboard_model.dart';
import '../models/dental_specialities.dart';
import '../models/user_model.dart';

class GamificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Constants ---
  static const int POINTS_READ_PREP = 10;
  static const int POINTS_LIVE_ATTEND = 50;
  static const int POINTS_INTERACTIVE_ANSWER = 20;
  static const int POINTS_CASE_COMPLETE = 100;

  // --- Point System ---

  // --- Helper Methods ---
  Future<bool> hasCompletedCase(String userId, String caseId) async {
    final query = await _firestore
        .collection('userPointsEvents')
        .where('userId', isEqualTo: userId)
        .where('caseId', isEqualTo: caseId)
        .where('eventType', isEqualTo: 'case_complete')
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  Future<void> awardPoints({
    required String userId,
    required String eventType, // e.g. 'prep_read'
    required int points,
    String? caseId,
  }) async {
    // Prevent duplicate case complete
    if (eventType == 'case_complete' && caseId != null) {
      if (await hasCompletedCase(userId, caseId)) {
        debugPrint(
            'Case $caseId already completed by $userId. Skipping points.');
        return;
      }
    }

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

        // Prepare updates
        final Map<String, dynamic> updates = {
          'totalPoints': currentTotal + points
        };

        // 2b. Update Specialty Stats if caseId is provided
        if (caseId != null) {
          final caseDoc =
              await transaction.get(_firestore.collection('cases').doc(caseId));
          if (caseDoc.exists) {
            final cData = caseDoc.data()!;
            String rawVal = cData['specialtyKey'] as String? ?? '';
            if (rawVal.isEmpty) {
              rawVal = cData['speciality'] as String? ?? '';
            }
            final specialtyKey =
                DentalSpecialtyConfig.guessFromText(rawVal).name;

            // Get current stats for this specialty
            final userStatsMap =
                (userSnapshot.data() as Map<String, dynamic>)['specialtyStats']
                        as Map<String, dynamic>? ??
                    {};
            final currentStatsData =
                userStatsMap[specialtyKey] as Map<String, dynamic>?;

            int currentCases = 0;
            int currentXp = 0;
            if (currentStatsData != null) {
              currentCases = currentStatsData['casesSolved'] as int? ?? 0;
              currentXp = currentStatsData['xp'] as int? ?? 0;
            }

            // Increment logic
            // Note: For 'interactive_answer', we might not count as 'casesSolved' unless it completes the case.
            // But strict requirement says "solving ... increments XP".
            // We will increment XP here.
            // For casesSolved, we probably only increment if the eventType is 'case_complete' or we decide interactive implies it.
            // Let's assume 'interactive_answer' adds XP but NOT casesSolved,
            // unless we add a specific event for completion.
            // BUT, for simplicity in MVP, if points >= 100 (full case), maybe we increment solved?
            // Let's just increment XP for now. 'casesSolved' is handled by Admin Grading or strict completion.

            final newStats = {
              'casesSolved':
                  currentCases, // Keep same unless typical completion
              'xp': currentXp + points,
            };

            // Construct the nested update path
            // Firestore dot notation for map fields: "specialtyStats.endodontics"
            updates['specialtyStats.$specialtyKey'] = newStats;
          }
        }

        transaction.update(userRef, updates);

        // 3. (Optional) Update Leaderboards
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

  // Revised Badge Check Logic returning newly earned badges
  Future<List<BadgeConfig>> checkAndAwardBadgesForUser(String userId) async {
    final List<BadgeConfig> newBadges = [];

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return [];

      final user = UserModel.fromJson(userDoc.data()!);
      final existingBadges = user.badges.toSet();

      // 1. General Point Badges
      if (user.totalPoints > 0 && !existingBadges.contains('first_step')) {
        newBadges.add(AVAILABLE_BADGES.firstWhere((b) => b.id == 'first_step'));
      }
      if (user.totalPoints >= 500 &&
          !existingBadges.contains('dedicated_student')) {
        newBadges.add(
            AVAILABLE_BADGES.firstWhere((b) => b.id == 'dedicated_student'));
      }

      // 2. Specialty Badges (Using Stats)
      // Helper to check stats for a badge
      void checkSpecialtyBadge(
          String badgeId, String specialtyKey, int requiredCases) {
        if (existingBadges.contains(badgeId)) return;

        final stats = user.specialtyStats[specialtyKey];
        if (stats != null && stats.casesSolved >= requiredCases) {
          final badge = AVAILABLE_BADGES.firstWhere((b) => b.id == badgeId,
              orElse: () => BadgeConfig(
                  id: badgeId,
                  name: 'New Badge',
                  description: '',
                  iconPath: ''));
          if (badge.id.isNotEmpty && badge.description.isNotEmpty) {
            // Ensure valid badge
            newBadges.add(badge);
          }
        }
      }

      // Define rules here (or iterate a config map)
      checkSpecialtyBadge('endo_starter', 'endodontics', 1);
      checkSpecialtyBadge('endo_master', 'endodontics', 5);
      // Example placeholders for others:
      checkSpecialtyBadge('ortho_starter', 'orthodontics', 1);

      // 3. Award Badges (Update DB)
      if (newBadges.isNotEmpty) {
        final newBadgeIds = newBadges.map((b) => b.id).toList();

        // Update User Document with new badges array
        await _firestore
            .collection('users')
            .doc(userId)
            .update({'badges': FieldValue.arrayUnion(newBadgeIds)});

        // Also add to legacy subcollection for backward compat if needed (optional)
        // keeping existing subcollection logic for certificates or detailed audit trails
        for (final badge in newBadges) {
          await _grantBadgeToSubcollection(userId, badge.id);
        }
      }
    } catch (e) {
      debugPrint("Badge check error: $e");
    }

    return newBadges;
  }

  @Deprecated('Use checkAndAwardBadgesForUser instead')
  Future<void> checkBadges(String userId) async {
    await checkAndAwardBadgesForUser(userId);
  }

  // Renamed internal method to be explicit about subcollection usage
  Future<void> _grantBadgeToSubcollection(String userId, String badgeId) async {
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
