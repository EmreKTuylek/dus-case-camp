import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/case_model.dart';

class UserListService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  // Generic method to add a case to a specific list
  Future<void> _addToList(String listName, CaseModel caseModel) async {
    if (_userId == null) return;
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection(listName)
        .doc(caseModel.id)
        .set({
      'caseId': caseModel.id,
      'addedAt': FieldValue.serverTimestamp(),
      // Store minimal details to display in list without fetching case again if needed
      'title': caseModel.title,
      'speciality': caseModel.speciality,
      'level': caseModel.level.name,
    });
  }

  // Generic method to remove a case from a specific list
  Future<void> _removeFromList(String listName, String caseId) async {
    if (_userId == null) return;
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection(listName)
        .doc(caseId)
        .delete();
  }

  // Check if case is in list
  Future<bool> _isInList(String listName, String caseId) async {
    if (_userId == null) return false;
    final doc = await _firestore
        .collection('users')
        .doc(_userId)
        .collection(listName)
        .doc(caseId)
        .get();
    return doc.exists;
  }

  // Stream of list logic
  Stream<List<String>> _listStream(String listName) {
    if (_userId == null) return const Stream.empty();
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection(listName)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  // Public API

  Future<void> addToFavorites(CaseModel caseModel) =>
      _addToList('favorites', caseModel);
  Future<void> removeFromFavorites(String caseId) =>
      _removeFromList('favorites', caseId);
  Future<bool> isFavorite(String caseId) => _isInList('favorites', caseId);
  Stream<List<String>> get favoritesStream => _listStream('favorites');

  Future<void> addToWatchLater(CaseModel caseModel) =>
      _addToList('watchLater', caseModel);
  Future<void> removeFromWatchLater(String caseId) =>
      _removeFromList('watchLater', caseId);
  Future<bool> isWatchLater(String caseId) => _isInList('watchLater', caseId);
  Stream<List<String>> get watchLaterStream => _listStream('watchLater');
}
