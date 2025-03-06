// lib/features/cards/presentation/widgets/filter_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/filter_provider.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/filter_options_provider.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/set_card_count_provider.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/filter_collection_provider.dart';
import 'package:fftcg_companion/core/utils/logger.dart';

/// A provider to prefetch filter options before showing the dialog
/// This helps reduce the loading time when opening the filter dialog
final prefetchFilterOptionsProvider = FutureProvider.autoDispose((ref) async {
  // Start loading filter options
  final options = await ref.watch(filterOptionsNotifierProvider.future);

  // Prefetch a few set counts to warm up the cache
  final allSetIds = options.set.toList();

  // Only prefetch a few sets to avoid too many concurrent requests
  for (final setId in allSetIds.take(10)) {
    ref.read(filteredSetCardCountCacheProvider(setId).future).ignore();
  }

  talker.debug('Prefetched filter options and some set counts');
  return options;
});

class FilterDialog extends ConsumerWidget {
  const FilterDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Trigger prefetch of filter options
    ref.watch(prefetchFilterOptionsProvider);

    final filterOptions = ref.watch(filterOptionsNotifierProvider);
    final filters = ref.watch(filterProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;

    // Calculate dialog dimensions
    final dialogWidth = size.width < 600 ? size.width * 0.9 : size.width * 0.6;
    final dialogMaxWidth = dialogWidth.clamp(300.0, 600.0);

    return Dialog(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogMaxWidth,
          maxHeight: size.height * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Filter Cards',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
              ).animate().fadeIn(duration: 300.ms),
              const SizedBox(height: 16),
              Flexible(
                child: filterOptions.when(
                  data: (options) => SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFilterSection(
                          context,
                          'Elements',
                          options.elements,
                          filters.elements,
                          (element) => ref
                              .read(filterProvider.notifier)
                              .toggleElement(element),
                        ).animate().fadeIn(delay: 100.ms),
                        Divider(color: colorScheme.outlineVariant),
                        _buildFilterSection(
                          context,
                          'Types',
                          options.types,
                          filters.types,
                          (type) => ref
                              .read(filterProvider.notifier)
                              .toggleType(type),
                        ).animate().fadeIn(delay: 200.ms),
                        Divider(color: colorScheme.outlineVariant),
                        _buildFilterSection(
                          context,
                          'Rarities',
                          options.rarities,
                          filters.rarities,
                          (rarity) => ref
                              .read(filterProvider.notifier)
                              .toggleRarity(rarity),
                          // No need for display names since we're using full names
                        ).animate().fadeIn(delay: 300.ms),
                        Divider(color: colorScheme.outlineVariant),
                        // Add Category filter section using Consumer for better reactivity
                        Consumer(
                          builder: (context, ref, child) {
                            final filterCollection =
                                ref.watch(filterCollectionProvider);

                            return filterCollection.when(
                              data: (collection) {
                                // Display categories from the "category" document
                                talker.debug(
                                    'Categories found: ${collection.category.length}');

                                if (collection.category.isEmpty) {
                                  talker.debug(
                                      'No categories found in collection');
                                  return const SizedBox.shrink();
                                }

                                return _buildFilterSection(
                                  context,
                                  'Categories',
                                  collection.category
                                      .toSet(), // Use the values from the category document
                                  filters
                                      .categories, // Current selected categories
                                  (category) => ref
                                      .read(filterProvider.notifier)
                                      .toggleCategory(category),
                                ).animate().fadeIn(delay: 350.ms);
                              },
                              loading: () => const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                              error: (error, stack) => Text(
                                'Error loading categories',
                                style: TextStyle(color: colorScheme.error),
                              ),
                            );
                          },
                        ),
                        Divider(color: colorScheme.outlineVariant),
                        _buildGroupedSetsSection(
                          context,
                          options.set,
                          filters.set,
                          ref,
                          colorScheme,
                        ).animate().fadeIn(delay: 400.ms),
                        if (options.costRange.$1 != options.costRange.$2)
                          _buildCollapsibleRangeSlider(
                            context,
                            'Cost',
                            options.costRange.$1.toDouble(),
                            options.costRange.$2.toDouble(),
                            filters.minCost?.toDouble(),
                            filters.maxCost?.toDouble(),
                            (min, max) =>
                                ref.read(filterProvider.notifier).setCostRange(
                                      min?.toInt(),
                                      max?.toInt(),
                                    ),
                          ).animate().fadeIn(delay: 500.ms),
                        if (options.powerRange.$1 != options.powerRange.$2)
                          _buildCollapsibleRangeSlider(
                            context,
                            'Power',
                            options.powerRange.$1.toDouble(),
                            options.powerRange.$2.toDouble(),
                            filters.minPower?.toDouble(),
                            filters.maxPower?.toDouble(),
                            (min, max) =>
                                ref.read(filterProvider.notifier).setPowerRange(
                                      min?.toInt(),
                                      max?.toInt(),
                                    ),
                          ).animate().fadeIn(delay: 600.ms),
                        Divider(color: colorScheme.outlineVariant),
                        _buildSwitchRow(
                          context,
                          'Show Sealed Products',
                          filters.showSealedProducts,
                          (_) => ref
                              .read(filterProvider.notifier)
                              .toggleShowSealedProducts(),
                        ).animate().fadeIn(delay: 700.ms),
                      ],
                    ),
                  ),
                  loading: () => Center(
                    child: CircularProgressIndicator(
                      color: colorScheme.primary,
                    ),
                  ),
                  error: (error, stack) => Text(
                    error.toString(),
                    style: TextStyle(color: colorScheme.error),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => ref.read(filterProvider.notifier).reset(),
                    child: Text('Reset',
                        style: TextStyle(color: colorScheme.primary)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel',
                        style: TextStyle(color: colorScheme.primary)),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, filters),
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                    ),
                    child: const Text('Apply'),
                  ),
                ],
              ).animate().slideY(
                    begin: 1,
                    end: 0,
                    delay: 200.ms,
                    duration: 400.ms,
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection(
    BuildContext context,
    String title,
    Set<String> options,
    Set<String> selectedValues,
    void Function(String) onToggle, {
    Map<String, String>? displayNames,
  }) {
    // Check if any options from this section are selected
    final hasSelectedOptions = selectedValues.isNotEmpty;
    final colorScheme = Theme.of(context).colorScheme;

    return ExpansionTile(
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      // Only expand if options from this section are selected
      initiallyExpanded: hasSelectedOptions,
      collapsedIconColor: colorScheme.onSurface,
      iconColor: colorScheme.primary,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final displayName = displayNames?[option] ?? option;
              return FilterChip(
                label: Text(displayName),
                selected: selectedValues.contains(option),
                onSelected: (_) => onToggle(option),
                showCheckmark: true,
              );
            }).toList(),
          ).animate().fadeIn(duration: 150.ms),
        ),
      ],
    );
  }

  Widget _buildGroupedSetsSection(
    BuildContext context,
    Set<String> options,
    Set<String> selectedValues,
    WidgetRef ref,
    ColorScheme colorScheme,
  ) {
    final filterOptionsNotifier =
        ref.watch(filterOptionsNotifierProvider.notifier);
    final groupedSets = filterOptionsNotifier.getGroupedSets();

    // Check if any sets are selected
    final hasSelectedSets = selectedValues.isNotEmpty;

    return ExpansionTile(
      title: Text(
        'Sets',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      // Only expand if sets are selected
      initiallyExpanded: hasSelectedSets,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...SetCategory.values.map((category) {
                final sets = groupedSets[category] ?? [];
                if (sets.isEmpty) return const SizedBox.shrink();

                return _buildSetCategory(
                  context,
                  category,
                  sets,
                  selectedValues,
                  ref,
                  colorScheme,
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSetCategory(
    BuildContext context,
    SetCategory category,
    List<String> sets,
    Set<String> selectedValues,
    WidgetRef ref,
    ColorScheme colorScheme,
  ) {
    final filterOptionsNotifier =
        ref.watch(filterOptionsNotifierProvider.notifier);

    // Check if any sets from this category are selected
    final hasSelectedSetsInCategory =
        sets.any((setId) => selectedValues.contains(setId));

    return ExpansionTile(
      title: Text(
        switch (category) {
          SetCategory.promotional => 'Promotional Sets',
          SetCategory.collection => 'Collections & Decks',
          SetCategory.opus => 'Opus Sets',
        },
        style: Theme.of(context).textTheme.titleMedium,
      ),
      // Only expand if sets from this category are selected
      initiallyExpanded: hasSelectedSetsInCategory,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: sets.length,
          itemBuilder: (context, index) {
            final setId = sets[index];
            final setName = filterOptionsNotifier.getSetName(setId);
            final cardCount =
                ref.watch(filteredSetCardCountCacheProvider(setId));

            return FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      setName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Use our StatefulWidget to maintain the count during set selection
                  SetCardCountDisplay(
                    setId: setId,
                    cardCount: cardCount,
                    colorScheme: colorScheme,
                  ),
                ],
              ),
              selected: selectedValues.contains(setId),
              onSelected: (_) =>
                  ref.read(filterProvider.notifier).toggleSet(setId),
              backgroundColor: colorScheme.surfaceContainerHighest,
              selectedColor: colorScheme.primaryContainer,
              labelStyle: TextStyle(
                color: selectedValues.contains(setId)
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
            );
          },
        ).animate().fadeIn(duration: 150.ms),
      ],
    );
  }

  Widget _buildSwitchRow(
    BuildContext context,
    String title,
    bool value,
    void Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleRangeSlider(
    BuildContext context,
    String title,
    double min,
    double max,
    double? currentMin,
    double? currentMax,
    void Function(double?, double?) onChanged,
  ) {
    // Check if the range has been modified from default
    final isRangeModified = (currentMin != null && currentMin > min) ||
        (currentMax != null && currentMax < max);

    return ExpansionTile(
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      // Expand if range has been modified
      initiallyExpanded: isRangeModified,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: _buildRangeSlider(
            context,
            title,
            min,
            max,
            currentMin,
            currentMax,
            onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildRangeSlider(
    BuildContext context,
    String title,
    double min,
    double max,
    double? currentMin,
    double? currentMax,
    void Function(double?, double?) onChanged,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final effectiveMin = currentMin ?? min;
    final effectiveMax = currentMax ?? max;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Display the range value in a chip
        Align(
          alignment: Alignment.center,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16.0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              title == 'Power'
                  ? '${(effectiveMin / 1000).toInt()}k - ${(effectiveMax / 1000).toInt()}k'
                  : '${effectiveMin.toInt()} - ${effectiveMax.toInt()}',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        RangeSlider(
          values: RangeValues(effectiveMin, effectiveMax),
          min: min,
          max: max,
          divisions: title == 'Power'
              ? ((max - min) / 1000).toInt()
              : (max - min).toInt(),
          labels: RangeLabels(
            title == 'Power'
                ? '${(effectiveMin / 1000).toInt()}k'
                : effectiveMin.toInt().toString(),
            title == 'Power'
                ? '${(effectiveMax / 1000).toInt()}k'
                : effectiveMax.toInt().toString(),
          ),
          activeColor: colorScheme.primary,
          inactiveColor: colorScheme.surfaceVariant,
          onChanged: (RangeValues values) {
            onChanged(values.start, values.end);
          },
        ),
      ],
    );
  }
}

/// A StatefulWidget to maintain the card count during set selection
class SetCardCountDisplay extends StatefulWidget {
  final String setId;
  final AsyncValue<int> cardCount;
  final ColorScheme colorScheme;

  const SetCardCountDisplay({
    super.key,
    required this.setId,
    required this.cardCount,
    required this.colorScheme,
  });

  @override
  State<SetCardCountDisplay> createState() => _SetCardCountDisplayState();
}

class _SetCardCountDisplayState extends State<SetCardCountDisplay> {
  // Store the count once we have it
  int? _cachedCount;

  @override
  void initState() {
    super.initState();

    // Initialize cached count if data is already available
    if (widget.cardCount.hasValue) {
      _cachedCount = widget.cardCount.value;
    }
  }

  @override
  void didUpdateWidget(SetCardCountDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update cached count when data is available
    if (widget.cardCount.hasValue && !widget.cardCount.isLoading) {
      _cachedCount = widget.cardCount.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    // If we have a cached count, use it
    if (_cachedCount != null) {
      return Text(
        '($_cachedCount)',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    // Otherwise, show loading or error state
    return widget.cardCount.when(
      data: (count) {
        // Store the count for future use
        _cachedCount = count;
        return Text(
          '($count)',
          style: Theme.of(context).textTheme.bodySmall,
        );
      },
      loading: () => Text(
        '(...)',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: widget.colorScheme.onSurfaceVariant.withAlpha(128),
            ),
      ),
      error: (_, __) => Text(
        '(!)',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: widget.colorScheme.error,
            ),
      ),
    );
  }
}
