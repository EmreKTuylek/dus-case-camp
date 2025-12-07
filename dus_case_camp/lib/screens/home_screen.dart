import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/data_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/home_carousel.dart';
import '../widgets/case_card.dart';
import '../services/recommendation_service.dart';
import '../models/case_model.dart';
import '../l10n/app_localizations.dart';

// Simple provider for recommendations
final recommendationsProvider = FutureProvider<List<CaseModel>>((ref) async {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) return [];
  return RecommendationService().getRecommendations(user.uid);
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannersAsync = ref.watch(bannersProvider);
    final allCasesAsync = ref.watch(allCasesProvider);
    final recommendationsAsync = ref.watch(recommendationsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Navigation to search will be implemented with Library
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refresh(bannersProvider);
          ref.refresh(allCasesProvider);
          ref.refresh(recommendationsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // BANNERS CAROUSEL
              bannersAsync.when(
                data: (banners) => HomeCarousel(banners: banners),
                loading: () => const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator())),
                error: (_, __) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 24),

              // --- SMART RECOMMENDATIONS ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.amber),
                    const SizedBox(width: 8),
                    Text(
                      l10n.fillYourGaps,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              recommendationsAsync.when(
                data: (cases) {
                  if (cases.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(l10n.greatWork,
                          style: const TextStyle(color: Colors.grey)),
                    );
                  }
                  return SizedBox(
                    height: 220,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: cases.length,
                      itemBuilder: (context, index) {
                        final caseItem = cases[index];
                        return Container(
                          width: 280,
                          margin: const EdgeInsets.only(right: 16),
                          child: CaseCard(
                            caseModel: caseItem,
                            onTap: () =>
                                context.go('/home/case/${caseItem.id}'),
                            compact: true,
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator())),
                error: (e, s) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 24),

              // RECENT CASES HEADER
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.latestCases,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () {
                        context.go('/library');
                      },
                      child: Text(l10n.viewAll),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // CASE FEED
              allCasesAsync.when(
                data: (cases) {
                  if (cases.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(child: Text(l10n.noCases)),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cases.length,
                    itemBuilder: (context, index) {
                      final caseItem = cases[index];
                      return CaseCard(
                        caseModel: caseItem,
                        onTap: () => context.go('/home/case/${caseItem.id}'),
                      );
                    },
                  );
                },
                loading: () => const Center(
                    child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                )),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
