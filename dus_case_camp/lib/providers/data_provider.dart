import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/data_repository.dart';
import '../models/week_model.dart';
import '../models/case_model.dart';
import '../models/banner_model.dart';
import 'auth_provider.dart';

final dataRepositoryProvider = Provider<DataRepository>((ref) {
  return DataRepository(ref.watch(firestoreProvider));
});

final activeWeeksProvider = StreamProvider<List<WeekModel>>((ref) {
  return ref.watch(dataRepositoryProvider).getActiveWeeks();
});

final casesForWeekProvider =
    StreamProvider.family<List<CaseModel>, String>((ref, weekId) {
  return ref.watch(dataRepositoryProvider).getCasesForWeek(weekId);
});

final bannersProvider = StreamProvider<List<BannerModel>>((ref) {
  return ref.watch(dataRepositoryProvider).getBanners();
});

final allCasesProvider = StreamProvider<List<CaseModel>>((ref) {
  return ref.watch(dataRepositoryProvider).getAllCases();
});
