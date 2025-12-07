import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/week_model.dart';
import '../models/case_model.dart';
import '../models/banner_model.dart';

class DataRepository {
  final FirebaseFirestore _firestore;

  DataRepository(this._firestore);

  Stream<List<WeekModel>> getActiveWeeks() {
    return _firestore
        .collection('weeks')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WeekModel.fromJson(doc.data()))
            .toList());
  }

  Stream<List<CaseModel>> getCasesForWeek(String weekId) {
    return _firestore
        .collection('cases')
        .where('weekId', isEqualTo: weekId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CaseModel.fromJson(doc.data()))
            .toList());
  }

  Stream<List<BannerModel>> getBanners() {
    return _firestore
        .collection('banners')
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BannerModel.fromJson(doc.data()))
            .toList());
  }

  Stream<List<CaseModel>> getAllCases() {
    // For now, fetch all. In prod, might need limit/pagination.
    return _firestore
        .collection('cases')
        .orderBy('createdAt', descending: true)
        .limit(20) // Limit for performance
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CaseModel.fromJson(doc.data()))
            .toList());
  }
}
