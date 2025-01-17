// lib/features/cards/presentation/widgets/filter_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fftcg_companion/features/cards/domain/models/card_filters.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/filter_options_provider.dart';
import 'package:fftcg_companion/shared/widgets/element_icon.dart';
import 'package:fftcg_companion/features/cards/domain/models/element_type.dart';

final filterProvider =
    StateNotifierProvider<FilterNotifier, CardFilters>((ref) {
  return FilterNotifier();
});

class FilterNotifier extends StateNotifier<CardFilters> {
  FilterNotifier() : super(const CardFilters());

  void toggleElement(String element) {
    final elements = Set<String>.from(state.elements);
    if (elements.contains(element)) {
      elements.remove(element);
    } else {
      elements.add(element);
    }
    state = state.copyWith(elements: elements);
  }

  void toggleType(String type) {
    final types = Set<String>.from(state.types);
    if (types.contains(type)) {
      types.remove(type);
    } else {
      types.add(type);
    }
    state = state.copyWith(types: types);
  }

  void toggleCategory(String category) {
    final categories = Set<String>.from(state.categories);
    if (categories.contains(category)) {
      categories.remove(category);
    } else {
      categories.add(category);
    }
    state = state.copyWith(categories: categories);
  }

  void toggleJob(String job) {
    final jobs = Set<String>.from(state.jobs);
    if (jobs.contains(job)) {
      jobs.remove(job);
    } else {
      jobs.add(job);
    }
    state = state.copyWith(jobs: jobs);
  }

  void toggleRarity(String rarity) {
    final rarities = Set<String>.from(state.rarities);
    if (rarities.contains(rarity)) {
      rarities.remove(rarity);
    } else {
      rarities.add(rarity);
    }
    state = state.copyWith(rarities: rarities);
  }

  void setCostRange(int? min, int? max) {
    state = state.copyWith(minCost: min, maxCost: max);
  }

  void reset() {
    state = const CardFilters();
  }
}

class FilterDialog extends ConsumerWidget {
  const FilterDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterOptions = ref.watch(filterOptionsNotifierProvider);
    final filters = ref.watch(filterProvider);

    return Dialog(
      child: filterOptions.when(
        data: (options) => Container(
          constraints: const BoxConstraints(
            maxWidth: 600,
            maxHeight: 800,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('Filter Cards'),
                actions: [
                  TextButton(
                    onPressed: () {
                      ref.read(filterProvider.notifier).reset();
                    },
                    child: const Text('Reset'),
                  ),
                ],
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Elements Section
                    _buildSectionTitle(context, 'Elements'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ElementType.values.map((element) {
                        final isSelected =
                            filters.elements.contains(element.name);
                        return InkWell(
                          onTap: () => ref
                              .read(filterProvider.notifier)
                              .toggleElement(element.name),
                          borderRadius: BorderRadius.circular(20),
                          child: ElementIcon(
                            element: element,
                            size: 40,
                            selected: isSelected,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Card Types Section
                    _buildFilterSection(
                      context,
                      'Card Types',
                      options.types,
                      filters.types,
                      (type) =>
                          ref.read(filterProvider.notifier).toggleType(type),
                    ),

                    // Categories Section
                    _buildFilterSection(
                      context,
                      'Categories',
                      options.categories,
                      filters.categories,
                      (category) => ref
                          .read(filterProvider.notifier)
                          .toggleCategory(category),
                    ),

                    // Cost Range Section
                    _buildCostRangeSection(
                      context,
                      options.costRange,
                      filters,
                      ref,
                    ),

                    // Jobs Section
                    _buildFilterSection(
                      context,
                      'Jobs',
                      options.jobs,
                      filters.jobs,
                      (job) => ref.read(filterProvider.notifier).toggleJob(job),
                    ),

                    // Rarities Section
                    _buildFilterSection(
                      context,
                      'Rarities',
                      options.rarities,
                      filters.rarities,
                      (rarity) => ref
                          .read(filterProvider.notifier)
                          .toggleRarity(rarity),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, filters),
                      child: const Text('Apply'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildFilterSection(
    BuildContext context,
    String title,
    Set<String> options,
    Set<String> selectedValues,
    void Function(String) onToggle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, title),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            return FilterChip(
              label: Text(option),
              selected: selectedValues.contains(option),
              onSelected: (_) => onToggle(option),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCostRangeSection(
    BuildContext context,
    (int, int) costRange,
    CardFilters filters,
    WidgetRef ref,
  ) {
    final (minCost, maxCost) = costRange;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Cost Range'),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int?>(
                decoration: const InputDecoration(
                  labelText: 'Min Cost',
                ),
                value: filters.minCost,
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Any'),
                  ),
                  ...List.generate(
                    maxCost + 1,
                    (i) => DropdownMenuItem(
                      value: i,
                      child: Text(i.toString()),
                    ),
                  ),
                ],
                onChanged: (value) => ref
                    .read(filterProvider.notifier)
                    .setCostRange(value, filters.maxCost),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<int?>(
                decoration: const InputDecoration(
                  labelText: 'Max Cost',
                ),
                value: filters.maxCost,
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Any'),
                  ),
                  ...List.generate(
                    maxCost + 1,
                    (i) => DropdownMenuItem(
                      value: i,
                      child: Text(i.toString()),
                    ),
                  ),
                ],
                onChanged: (value) => ref
                    .read(filterProvider.notifier)
                    .setCostRange(filters.minCost, value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
