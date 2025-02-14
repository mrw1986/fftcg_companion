import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
              Expanded(child: _buildSearchField())
            else
              Flexible(
                child: SizedBox(
                  width: size.width * 0.4,
                  child: _buildSearchField(),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: controller,
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'Search cards...',
        border: InputBorder.none,
        suffixIcon: IconButton(
          icon: const Icon(Icons.backspace_outlined),
          onPressed: () => controller.clear(),
        ),
      ),
      onChanged: (_) {},
    );
  }
}
