import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/gamification_service.dart';
import '../models/gamification_models.dart';
import 'auth_provider.dart';

final gamificationServiceProvider = Provider((ref) => GamificationService());

final userBadgesProvider = StreamProvider<List<UserBadge>>((ref) {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) return Stream.value([]);
  return ref.watch(gamificationServiceProvider).getUserBadges(user.uid);
});

final userCertificatesProvider = StreamProvider<List<UserCertificate>>((ref) {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) return Stream.value([]);
  return ref.watch(gamificationServiceProvider).getUserCertificates(user.uid);
});
