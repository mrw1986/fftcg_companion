// lib/features/collection/presentation/widgets/collection_filter_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/filter_options_provider.dart';
// Import the correct filter provider for the collection view
import 'package:fftcg_companion/features/collection/presentation/providers/collection_filter_provider.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/filter_collection_provider.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/set_card_count_provider.dart';
// Import only needed widget from cards filter dialog
import 'package:fftcg_companion/features/cards/presentation/widgets/filter_dialog.dart'
    show
        SetCardCountDisplay,
        prefetchFilterOptionsProvider; // Added prefetch provider
import 'package:fftcg_companion/core/utils/logger.dart';
import '../../domain/providers/collection_providers.dart';
// Import CardFilters model
import 'package:fftcg_companion/features/cards/domain/models/card_filters.dart';

/// Collection filter dialog that combines Cards filter options with Collection-specific filters
class CollectionFilterDialog extends ConsumerWidget {
  const CollectionFilterDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Trigger prefetch of filter options
    ref.watch(prefetchFilterOptionsProvider);

    final filterOptions = ref.watch(filterOptionsNotifierProvider);
    // Watch the shared card filters provider for the collection view
    final cardsFilters = ref.watch(collectionFilterProvider);
    // Watch the collection-specific filters provider
    final collectionSpecificFilters =
        ref.watch(collectionSpecificFilterProvider);
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
                'Filter Collection',
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
                        // Collection-specific filters
                        _buildCollectionFiltersSection(
                          context,
                          ref,
                          collectionSpecificFilters, // Pass the specific filters map
                        ).animate().fadeIn(delay: 50.ms),

                        // --- Add Status Filter Section ---
                        _buildStatusFilterSection(context, ref, cardsFilters)
                            .animate()
                            .fadeIn(delay: 75.ms), // Adjust delay
                        // --- End Status Filter Section ---

                        // Card filters from the Cards page
                        _buildFilterSection(
                          context,
                          'Elements',
                          options.elements,
                          cardsFilters.elements,
                          (element) => ref
                              .read(collectionFilterProvider
                                  .notifier) // Use collection provider
                              .toggleElement(element),
                        ).animate().fadeIn(delay: 100.ms),
                        _buildFilterSection(
                          context,
                          'Types',
                          options.types,
                          cardsFilters.types,
                          (type) => ref
                              .read(collectionFilterProvider
                                  .notifier) // Use collection provider
                              .toggleType(type),
                        ).animate().fadeIn(delay: 200.ms),
                        _buildFilterSection(
                          context,
                          'Rarities',
                          options.rarities,
                          cardsFilters.rarities,
                          (rarity) => ref
                              .read(collectionFilterProvider
                                  .notifier) // Use collection provider
                              .toggleRarity(rarity),
                        ).animate().fadeIn(delay: 300.ms),
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
                                  cardsFilters
                                      .categories, // Current selected categories
                                  (category) => ref
                                      .read(collectionFilterProvider
                                          .notifier) // Use collection provider
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
                        _buildGroupedSetsSection(
                          context,
                          options.set,
                          cardsFilters.set,
                          ref,
                          colorScheme,
                        ).animate().fadeIn(delay: 400.ms),
                        if (options.costRangeTuple.$1 !=
                            options.costRangeTuple.$2)
                          _buildCollapsibleRangeSlider(
                            context,
                            'Cost',
                            options.costRangeTuple.$1.toDouble(),
                            options.costRangeTuple.$2.toDouble(),
                            cardsFilters.minCost?.toDouble(),
                            cardsFilters.maxCost?.toDouble(),
                            (min, max) => ref
                                .read(collectionFilterProvider.notifier)
                                .setCostRange(
                                  // Use collection provider
                                  min?.toInt(),
                                  max?.toInt(),
                                ),
                          ).animate().fadeIn(delay: 500.ms),
                        if (options.powerRangeTuple.$1 !=
                            options.powerRangeTuple.$2)
                          _buildCollapsibleRangeSlider(
                            context,
                            'Power',
                            options.powerRangeTuple.$1.toDouble(),
                            options.powerRangeTuple.$2.toDouble(),
                            cardsFilters.minPower?.toDouble(),
                            cardsFilters.maxPower?.toDouble(),
                            (min, max) => ref
                                .read(collectionFilterProvider.notifier)
                                .setPowerRange(
                                  // Use collection provider
                                  min?.toInt(),
                                  max?.toInt(),
                                ),
                          ).animate().fadeIn(delay: 600.ms),
                        _buildSwitchRow(
                          context,
                          'Show Sealed Products',
                          cardsFilters.showSealedProducts,
                          (_) => ref
                              .read(collectionFilterProvider
                                  .notifier) // Use collection provider
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
                    onPressed: () {
                      // Reset shared card filters for collection
                      ref.read(collectionFilterProvider.notifier).reset();
                      // Reset collection-specific filters
                      ref
                          .read(collectionSpecificFilterProvider.notifier)
                          .clearFilters();
                    },
                    child: Text('Reset',
                        style: TextStyle(color: colorScheme.primary)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel',
                        style: TextStyle(color: colorScheme.primary)),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(
                      context,
                      (
                        cardsFilters,
                        collectionSpecificFilters
                      ), // Return correct filters
                      // Apply both filters when the Apply button is pressed
                    ),
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

  Widget _buildCollectionFiltersSection(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> collectionSpecificFilters, // Use specific filters map
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return ExpansionTile(
      title: Text(
        'Collection Filters',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      initiallyExpanded: true,
      collapsedIconColor: colorScheme.onSurface,
      iconColor: colorScheme.primary,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildCollectionFilterChip(
                    context,
                    ref,
                    'Regular',
                    'type',
                    'regular',
                    Icons.copy,
                    collectionSpecificFilters, // Use specific filters map
                  ),
                  _buildCollectionFilterChip(
                    context,
                    ref,
                    'Foil',
                    'type',
                    'foil',
                    Icons.star,
                    collectionSpecificFilters, // Use specific filters map
                  ),
                  _buildCollectionFilterChip(
                    context,
                    ref,
                    'Graded',
                    'graded',
                    true,
                    Icons.verified,
                    collectionSpecificFilters, // Use specific filters map
                  ),
                ],
              ),
              if (collectionSpecificFilters.containsKey('graded') &&
                  collectionSpecificFilters['graded'] == true)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: _buildGradingCompanyDropdown(
                    context,
                    ref,
                    collectionSpecificFilters, // Use specific filters map
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCollectionFilterChip(
    BuildContext context,
    WidgetRef ref,
    String label,
    String filterKey,
    dynamic filterValue,
    IconData icon,
    Map<String, dynamic> collectionSpecificFilters, // Use specific filters map
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = collectionSpecificFilters[filterKey] == filterValue;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        // Use the notifier methods to update the state
        if (selected) {
          ref
              .read(collectionSpecificFilterProvider.notifier)
              .setFilter(filterKey, filterValue);
        } else {
          ref
              .read(collectionSpecificFilterProvider.notifier)
              .removeFilter(filterKey);
        }
      },
      backgroundColor: colorScheme.surface,
      selectedColor: colorScheme.primaryContainer,
      checkmarkColor: colorScheme.onPrimaryContainer,
      showCheckmark: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.outlineVariant,
          width: 1,
        ),
      ),
    );
  }

  Widget _buildGradingCompanyDropdown(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> collectionSpecificFilters, // Use specific filters map
  ) {
    return DropdownButtonFormField<String?>(
      value: collectionSpecificFilters['gradingCompany'],
      decoration: InputDecoration(
        labelText: 'Grading Company',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: const [
        DropdownMenuItem<String?>(
          value: null,
          child: Text('Any Company'),
        ),
        DropdownMenuItem<String?>(
          value: 'PSA',
          child: Text('PSA'),
        ),
        DropdownMenuItem<String?>(
          value: 'BGS',
          child: Text('BGS'),
        ),
        DropdownMenuItem<String?>(
          value: 'CGC',
          child: Text('CGC'),
        ),
      ],
      onChanged: (value) {
        // Use the notifier methods to update the state
        if (value == null) {
          ref
              .read(collectionSpecificFilterProvider.notifier)
              .removeFilter('gradingCompany');
        } else {
          ref
              .read(collectionSpecificFilterProvider.notifier)
              .setFilter('gradingCompany', value);
        }
      },
    );
  }

  // --- NEW: Status Filter Section ---
  Widget _buildStatusFilterSection(
      BuildContext context, WidgetRef ref, CardFilters filters) {
    final colorScheme = Theme.of(context).colorScheme;
    // Check if either status filter is active
    final hasSelectedOptions =
        filters.showFavoritesOnly || filters.showWishlistOnly;

    return ExpansionTile(
      title: Text(
        'Status',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      initiallyExpanded: hasSelectedOptions, // Expand if a status is selected
      collapsedIconColor: colorScheme.onSurface,
      iconColor: colorScheme.primary,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('Favorites'),
                avatar: Icon(
                  filters.showFavoritesOnly ? Icons.star : Icons.star_border,
                  color: filters.showFavoritesOnly
                      ? Colors.amber
                      : colorScheme.onSurfaceVariant,
                ),
                selected: filters.showFavoritesOnly,
                onSelected: (selected) {
                  // Use collectionFilterProvider here
                  ref
                      .read(collectionFilterProvider.notifier)
                      .toggleShowFavoritesOnly();
                },
                showCheckmark: false, // Use avatar instead
              ),
              FilterChip(
                label: const Text('Wishlist'),
                avatar: Icon(
                  filters.showWishlistOnly
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                  color: filters.showWishlistOnly
                      ? colorScheme.tertiary
                      : colorScheme.onSurfaceVariant,
                ),
                selected: filters.showWishlistOnly,
                onSelected: (selected) {
                  // Use collectionFilterProvider here
                  ref
                      .read(collectionFilterProvider.notifier)
                      .toggleShowWishlistOnly();
                },
                showCheckmark: false, // Use avatar instead
              ),
            ],
          ).animate().fadeIn(duration: 150.ms),
        ),
      ],
    );
  }
  // --- End Status Filter Section ---

  // Reuse the filter section widgets from the Cards filter dialog
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
                  // Use the correct provider for shared card filters
                  ref.read(collectionFilterProvider.notifier).toggleSet(setId),
              // This applies the set filter
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
          inactiveColor: colorScheme.surfaceContainerHighest,
          onChanged: (RangeValues values) {
            onChanged(values.start, values.end);
          },
        ),
      ],
    );
  }
}
