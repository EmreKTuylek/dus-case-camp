import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/case_model.dart';
import 'package:flutter/foundation.dart';

class RecommendationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Suggests cases based on "Fill Your Gaps" logic.
  /// 1. Finds specialties with low activity or low scores.
  /// 2. Fetches available cases in those specialties.
  Future<List<CaseModel>> getRecommendations(String userId) async {
    try {
      // 1. Fetch User Stats (Simulated or Real)
      // In a real app, we'd query 'userSpecialtyStats' collection.
      // For MVP, we'll pick a random specialty or check recent history locally.

      // Let's blindly checking for "Endodontics" and "Surgery" gaps for demo.
      // "Find cases in Endodontics that I haven't done yet".

      final casesRef = _firestore.collection('cases');

      // Fetch a few cases from a specific 'hard' specialty as a default recommendation
      // In production, prioritize specialties where user average score < 50.

      final snapshot = await casesRef
          .where('specialtyKey',
              isEqualTo: 'endodontics') // Example: recommending Endo key
          .limit(5)
          .get();

      final allCases =
          snapshot.docs.map((d) => CaseModel.fromJson(d.data())).toList();

      // Filter out cases the user has already completed checking 'userCompletedCases'
      // This requires an extra query, skipping for speed in MVP, returning all.

      return allCases;
    } catch (e) {
      debugPrint("Recommendation error: $e");
      return [];
    }
  }

  /// Determines which specialties are "Weak" for the user.
  Future<List<String>> getWeakSpecialties(String userId) async {
    // Placeholder logic
    return ['Endodontics', 'Oral Surgery'];
  }
}
