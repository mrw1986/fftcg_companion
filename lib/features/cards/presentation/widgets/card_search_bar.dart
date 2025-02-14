import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/search_provider.dart';

class CardSearchBar extends ConsumerWidget {
  final TextEditingController controller;
  final bool isSearching;
  final VoidCallback onSearchToggle;

  const CardSearchBar({
    super.key,
    required this.controller,
    required this.isSearching,
    required this.onSearchToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isSearching) {
      return const Text('Card Database');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = MediaQuery.sizeOf(context);
        final isSmallScreen = size.width <= size.shortestSide;

        return Row(
          children: [
            if (isSmallScreen)
              Expanded(child: _buildSearchField(ref))
            else
              Flexible(
                child: SizedBox(
                  width: size.width * 0.4,
                  child: _buildSearchField(ref),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSearchField(WidgetRef ref) {
    return TextField(
      controller: controller,
      autofocus: true,
      decoration: InputDecoration(
        hintText: "Search (e.g., 'Auron' or '1-001H')...",
        border: InputBorder.none,
        suffixIcon: IconButton(
          icon: const Icon(Icons.backspace_outlined),
          onPressed: () {
            controller.clear();
            ref.read(searchQueryProvider.notifier).state = '';
          },
        ),
      ),
      onChanged: (value) {
        ref.read(searchQueryProvider.notifier).state = value;
      },
    );
  }
}
