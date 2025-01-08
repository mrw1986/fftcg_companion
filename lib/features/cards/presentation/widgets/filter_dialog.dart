// lib/features/cards/presentation/widgets/filter_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fftcg_companion/features/cards/domain/models/card_filters.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/filter_options_provider.dart';

// Keep the existing provider
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

  void reset() {
    state = const CardFilters();
  }
}

// Add the FilterDialog widget
class FilterDialog extends ConsumerWidget {
  const FilterDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterOptions = ref.watch(filterOptionsNotifierProvider);
    final filters = ref.watch(filterProvider);

    return AlertDialog(
      title: const Text('Filter Cards'),
      content: filterOptions.when(
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
                (element) =>
                    ref.read(filterProvider.notifier).toggleElement(element),
              ),
              // Add more filter sections as needed
            ],
          ),
        ),
        loading: () => const CircularProgressIndicator(),
        error: (error, stack) => Text('Error: $error'),
      ),
      actions: [
        TextButton(
          onPressed: () {
            ref.read(filterProvider.notifier).reset();
            Navigator.pop(context);
          },
          child: const Text('Reset'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, filters),
          child: const Text('Apply'),
        ),
      ],
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
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        Wrap(
          spacing: 8,
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
}
