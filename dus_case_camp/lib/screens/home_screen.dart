import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/data_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/home_carousel.dart';
import '../widgets/case_card.dart';
import '../services/recommendation_service.dart';
import '../models/case_model.dart';
import '../models/dental_specialities.dart';
import '../l10n/app_localizations.dart';

// Simple provider for recommendations
final recommendationsProvider = FutureProvider<List<CaseModel>>((ref) async {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) return [];
  return RecommendationService().getRecommendations(user.uid);
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  DentalSpecialty? _selectedSpecialty;

  @override
  Widget build(BuildContext context) {
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

              const SizedBox(height: 16),

              // --- SPECIALTY FILTER ---
              SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: const Text('All'),
                        selected: _selectedSpecialty == null,
                        onSelected: (bool selected) {
                          setState(() {
                            _selectedSpecialty = null;
                          });
                        },
                      ),
                    ),
                    ...DentalSpecialty.values
                        .where((s) => s != DentalSpecialty.other)
                        .map((specialty) {
                      // Filter 'other' if needed, or keep it
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(DentalSpecialtyConfig.getLabel(specialty,
                              lang: 'tr')), // Localize if possible logic
                          selected: _selectedSpecialty == specialty,
                          onSelected: (bool selected) {
                            setState(() {
                              _selectedSpecialty = selected ? specialty : null;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // --- SMART RECOMMENDATIONS ---
              if (_selectedSpecialty == null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome,
                          color: Theme.of(context).colorScheme.secondary,
                          size: 20),
                      const SizedBox(width: 8),
                      Text(
                        l10n.fillYourGaps,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                recommendationsAsync.when(
                  data: (cases) {
                    if (cases.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(l10n.greatWork,
                            style: const TextStyle(color: Colors.grey)),
                      );
                    }
                    return SizedBox(
                      height: 240, // Slightly taller for polished card
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: cases.length,
                        itemBuilder: (context, index) {
                          final caseItem = cases[index];
                          return Container(
                            width: 260,
                            margin: const EdgeInsets.only(right: 12),
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
                      height: 120,
                      child: Center(child: CircularProgressIndicator())),
                  error: (e, s) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 32),
              ],

              // RECENT CASES HEADER
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedSpecialty == null
                          ? l10n.latestCases
                          : DentalSpecialtyConfig.getLabel(_selectedSpecialty!,
                              lang: 'tr'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (_selectedSpecialty == null)
                      TextButton(
                        onPressed: () {
                          context.go('/library');
                        },
                        child: Text(l10n.viewAll),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // CASE FEED
              allCasesAsync.when(
                data: (cases) {
                  // FILTERING LOGIC
                  final filteredCases = _selectedSpecialty == null
                      ? cases
                      : cases
                          .where(
                              (c) => c.specialtyKey == _selectedSpecialty!.name)
                          .toList();

                  if (filteredCases.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(child: Text(l10n.noCases)),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredCases.length,
                    itemBuilder: (context, index) {
                      final caseItem = filteredCases[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: CaseCard(
                          caseModel: caseItem,
                          onTap: () => context.go('/home/case/${caseItem.id}'),
                        ),
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
