import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/search_provider.dart';

class CardSearchBar extends ConsumerStatefulWidget {
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
  ConsumerState<CardSearchBar> createState() => _CardSearchBarState();
}

class _CardSearchBarState extends ConsumerState<CardSearchBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _widthAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _titleOpacityAnimation;
  late Animation<Offset> _slideAnimation;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _widthAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _titleOpacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Listen for text changes to show/hide the clear button
    widget.controller.addListener(_updateTextStatus);
  }

  void _updateTextStatus() {
    final hasText = widget.controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  @override
  void didUpdateWidget(CardSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_updateTextStatus);
      widget.controller.addListener(_updateTextStatus);
    }

    if (widget.isSearching != oldWidget.isSearching) {
      if (widget.isSearching) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateTextStatus);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        // Title that fades out when search is active
        AnimatedBuilder(
          animation: _titleOpacityAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _titleOpacityAnimation.value,
              child: child,
            );
          },
          child: const Text('Card Database'),
        ),

        // Search field that expands from right to left
        AnimatedBuilder(
          animation: _widthAnimation,
          builder: (context, child) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final size = MediaQuery.sizeOf(context);
                final isSmallScreen = size.width <= size.shortestSide;
                final maxWidth =
                    isSmallScreen ? constraints.maxWidth : size.width * 0.6;

                return SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    width: maxWidth * _widthAnimation.value,
                    alignment: Alignment.centerLeft,
                    child: Opacity(
                      opacity: _opacityAnimation.value,
                      child: child,
                    ),
                  ),
                );
              },
            );
          },
          child: _buildSearchField(ref),
        ),
      ],
    );
  }

  Widget _buildSearchField(WidgetRef ref) {
    return TextField(
      controller: widget.controller,
      autofocus: widget.isSearching,
      textAlignVertical: TextAlignVertical.center,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: "Search (e.g., 'Auron' or '1-001H')...",
        border: InputBorder.none,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        isDense: true,
        // Only show the clear button when there's text
        suffixIcon: _hasText
            ? IconButton(
                icon: const Icon(Icons.clear),
                tooltip: 'Clear search',
                onPressed: () {
                  widget.controller.clear();
                  ref.read(cardSearchQueryProvider.notifier).setQuery('');
                },
              )
            : null,
      ),
      onChanged: (value) {
        ref.read(cardSearchQueryProvider.notifier).setQuery(value);
      },
    );
  }
}
