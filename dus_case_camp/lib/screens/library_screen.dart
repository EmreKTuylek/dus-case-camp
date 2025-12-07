import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/data_provider.dart';
import '../models/case_model.dart';
import '../widgets/case_card.dart';
import '../models/dental_specialities.dart';
import '../l10n/app_localizations.dart';

// Local providers for filter state
final librarySearchProvider = StateProvider<String>((ref) => '');
final librarySpecialtyProvider = StateProvider<DentalSpecialty?>((ref) => null);
final libraryDifficultyProvider = StateProvider<CaseLevel?>((ref) => null);

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allCasesAsync = ref.watch(allCasesProvider);
    final searchQuery = ref.watch(librarySearchProvider);
    final selectedSpecialty = ref.watch(librarySpecialtyProvider);
    final selectedDifficulty = ref.watch(libraryDifficultyProvider);
    final l10n = AppLocalizations.of(context)!;

    // Determine current language code properly for data filtering if needed
    // But here we are just localizing UI.
    // For specific data localization (like specialty labels), we use the locale provider or just passed lang.
    // Assuming 'tr' for default if not found or get from l10n locale.
    final currentLang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.libraryTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog(
                  context, ref, selectedSpecialty, selectedDifficulty, l10n);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) =>
                  ref.read(librarySearchProvider.notifier).state = value,
              decoration: InputDecoration(
                hintText: l10n.searchHint,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context)
                    .colorScheme
                    .surfaceVariant
                    .withOpacity(0.5),
              ),
            ),
          ),

          // Specialty Chips (Horizontal)
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                FilterChip(
                  label: Text(l10n.filterAll),
                  selected: selectedSpecialty == null,
                  onSelected: (_) =>
                      ref.read(librarySpecialtyProvider.notifier).state = null,
                ),
                const SizedBox(width: 8),
                ...DentalSpecialty.values.map((specialty) {
                  if (specialty == DentalSpecialty.other)
                    return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(DentalSpecialtyConfig.getLabel(specialty,
                          lang: currentLang)),
                      selected: selectedSpecialty == specialty,
                      onSelected: (selected) {
                        ref.read(librarySpecialtyProvider.notifier).state =
                            selected ? specialty : null;
                      },
                    ),
                  );
                }).toList(),
              ],
            ),
          ),

          const Divider(),

          // Case Grid/List
          Expanded(
            child: allCasesAsync.when(
              data: (cases) {
                // Apply Filters
                final filteredCases = cases.where((c) {
                  final matchesSearch = c.title
                          .toLowerCase()
                          .contains(searchQuery.toLowerCase()) ||
                      c.description
                          .toLowerCase()
                          .contains(searchQuery.toLowerCase());
                  final matchesSpecialty = selectedSpecialty == null ||
                      c.specialtyKey == selectedSpecialty.name;
                  final matchesDifficulty = selectedDifficulty == null ||
                      c.level == selectedDifficulty;
                  return matchesSearch && matchesSpecialty && matchesDifficulty;
                }).toList();

                if (filteredCases.isEmpty) {
                  return Center(child: Text(l10n.noCasesFound));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: filteredCases.length,
                  itemBuilder: (context, index) {
                    final caseItem = filteredCases[index];
                    return CaseCard(
                      caseModel: caseItem,
                      onTap: () => context.go('/home/case/${caseItem.id}'),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(
      BuildContext context,
      WidgetRef ref,
      DentalSpecialty? currentSpecialty,
      CaseLevel? currentDifficulty,
      AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.filterDifficulty,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: Text(l10n.filterAny),
                    selected: currentDifficulty == null,
                    onSelected: (_) {
                      ref.read(libraryDifficultyProvider.notifier).state = null;
                      Navigator.pop(context);
                    },
                  ),
                  ...CaseLevel.values
                      .map((level) => FilterChip(
                            label: Text(level.name.toUpperCase()),
                            selected: currentDifficulty == level,
                            onSelected: (selected) {
                              ref
                                  .read(libraryDifficultyProvider.notifier)
                                  .state = selected ? level : null;
                              Navigator.pop(context);
                            },
                          ))
                      .toList(),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
