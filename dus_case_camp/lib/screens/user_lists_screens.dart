import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/user_list_service.dart';
import '../providers/data_provider.dart';
import '../widgets/case_card.dart';

// Since user lists are streams of IDs, we need to join with allCases to get models.
// A simpler way for MVP: fetch all cases and filter by IDs in list.
// Or create a new provider that does this efficiently.
// For now, I'll use the "filter all cases" approach as dataset is small.

final userListServiceProvider = Provider((ref) => UserListService());

final favoritesListProvider = StreamProvider<List<String>>((ref) {
  return ref.watch(userListServiceProvider).favoritesStream;
});

final watchLaterListProvider = StreamProvider<List<String>>((ref) {
  return ref.watch(userListServiceProvider).watchLaterStream;
});

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favIdsAsync = ref.watch(favoritesListProvider);
    final allCasesAsync = ref.watch(allCasesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Favorites')),
      body: favIdsAsync.when(
        data: (favIds) {
          if (favIds.isEmpty)
            return const Center(child: Text('No favorites yet.'));

          return allCasesAsync.when(
            data: (allCases) {
              final favoriteCases =
                  allCases.where((c) => favIds.contains(c.id)).toList();
              if (favoriteCases.isEmpty)
                return const Center(
                    child: Text('Favorites not found in cache.'));

              return ListView.builder(
                itemCount: favoriteCases.length,
                itemBuilder: (context, index) {
                  final c = favoriteCases[index];
                  return CaseCard(
                      caseModel: c,
                      onTap: () => context.go('/home/case/${c.id}'));
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error loading cases: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error loading favorites: $e')),
      ),
    );
  }
}

class WatchLaterScreen extends ConsumerWidget {
  const WatchLaterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wlIdsAsync = ref.watch(watchLaterListProvider);
    final allCasesAsync = ref.watch(allCasesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Watch Later')),
      body: wlIdsAsync.when(
        data: (ids) {
          if (ids.isEmpty)
            return const Center(child: Text('Watch list is empty.'));

          return allCasesAsync.when(
            data: (allCases) {
              final wlCases =
                  allCases.where((c) => ids.contains(c.id)).toList();
              if (wlCases.isEmpty)
                return const Center(child: Text('Cases not found in cache.'));

              return ListView.builder(
                itemCount: wlCases.length,
                itemBuilder: (context, index) {
                  final c = wlCases[index];
                  return CaseCard(
                      caseModel: c,
                      onTap: () => context.go('/home/case/${c.id}'));
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error loading cases: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error loading watch list: $e')),
      ),
    );
  }
}
