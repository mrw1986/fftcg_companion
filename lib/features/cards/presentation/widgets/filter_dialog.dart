// lib/features/cards/presentation/widgets/filter_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/filter_provider.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/filter_options_provider.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/set_card_count_provider.dart';

class FilterDialog extends ConsumerWidget {
  const FilterDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterOptions = ref.watch(filterOptionsNotifierProvider);
    final filters = ref.watch(filterProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;

    final dialogWidth = size.width < 600 ? size.width * 0.9 : size.width * 0.6;
    final maxWidth = dialogWidth.clamp(300.0, 600.0);

    return Dialog(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
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
                        ).animate().slideX().fadeIn(delay: 100.ms),
                        Divider(color: colorScheme.outlineVariant),
                        _buildFilterSection(
                          context,
                          'Types',
                          options.types,
                          filters.types,
                          (type) => ref
                              .read(filterProvider.notifier)
                              .toggleType(type),
                        ).animate().slideX().fadeIn(delay: 200.ms),
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
                        ).animate().slideX().fadeIn(delay: 300.ms),
                        Divider(color: colorScheme.outlineVariant),
                        _buildGroupedSetsSection(
                          context,
                          options.set,
                          filters.set,
                          ref,
                          colorScheme,
                        ).animate().slideX().fadeIn(delay: 400.ms),
                        if (options.costRange.$1 != options.costRange.$2)
                          _buildRangeSlider(
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
                          ).animate().slideX().fadeIn(delay: 500.ms),
                        if (options.powerRange.$1 != options.powerRange.$2)
                          _buildRangeSlider(
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
                          ).animate().slideX().fadeIn(delay: 600.ms),
                        Divider(color: colorScheme.outlineVariant),
                        _buildSwitchRow(
                          context,
                          'Show Sealed Products',
                          filters.showSealedProducts,
                          (_) => ref
                              .read(filterProvider.notifier)
                              .toggleShowSealedProducts(),
                        ).animate().slideX().fadeIn(delay: 700.ms),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final displayName = displayNames?[option] ?? option;
            return FilterChip(
              label: Text(displayName),
              selected: selectedValues.contains(option),
              onSelected: (_) => onToggle(option),
              showCheckmark: true,
            ).animate().scale(
                  duration: 200.ms,
                  delay: (50 * options.toList().indexOf(option)).ms,
                );
          }).toList(),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Sets',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
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
    final isOpusCategory = category == SetCategory.opus;

    return ExpansionTile(
      title: Text(
        switch (category) {
          SetCategory.promotional => 'Promotional Sets',
          SetCategory.collection => 'Collections & Decks',
          SetCategory.opus => 'Opus Sets',
        },
        style: Theme.of(context).textTheme.titleMedium,
      ),
      initiallyExpanded: isOpusCategory,
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
                  cardCount.when(
                    data: (count) => Text(
                      '($count)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    loading: () => const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (_, __) => const Text('(!)'),
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
            ).animate().scale(
                  duration: 200.ms,
                  delay: (50 * index).ms,
                );
          },
        ),
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
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: textTheme.titleMedium,
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    title == 'Power'
                        ? '${(effectiveMin / 1000).toInt()}k - ${(effectiveMax / 1000).toInt()}k'
                        : '${effectiveMin.toInt()} - ${effectiveMax.toInt()}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
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
          onChanged: (RangeValues values) {
            onChanged(values.start, values.end);
          },
        ),
      ],
    );
  }
}
