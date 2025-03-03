import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/search_provider.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/view_preferences_provider.dart';

class CardAppBarActions extends ConsumerStatefulWidget {
  final bool isSearching;
  final VoidCallback onSearchToggle;
  final VoidCallback onFilterTap;

  const CardAppBarActions({
    super.key,
    required this.isSearching,
    required this.onSearchToggle,
    required this.onFilterTap,
  });

  @override
  ConsumerState<CardAppBarActions> createState() => _CardAppBarActionsState();
}

class _CardAppBarActionsState extends ConsumerState<CardAppBarActions>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void didUpdateWidget(CardAppBarActions oldWidget) {
    super.didUpdateWidget(oldWidget);
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
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewPrefs = ref.watch(viewPreferencesProvider);
    final currentSize = viewPrefs.type == ViewType.grid
        ? viewPrefs.gridSize
        : viewPrefs.listSize;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search Toggle
        IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: Icon(
              widget.isSearching ? Icons.close : Icons.search,
              key: ValueKey<bool>(widget.isSearching),
            ),
          ),
          onPressed: () {
            if (widget.isSearching) {
              // Clear search state when closing search
              ref.read(searchQueryProvider.notifier).state = '';
            }
            widget.onSearchToggle();
          },
        ),

        // Filter Button - Always visible
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: widget.onFilterTap,
        ),

        // Other action buttons with fade animation
        AnimatedBuilder(
          animation: _opacityAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // View Type Toggle
                  IconButton(
                    icon: Icon(
                      viewPrefs.type == ViewType.grid
                          ? Icons.view_list
                          : Icons.grid_view,
                    ),
                    onPressed: _opacityAnimation.value > 0.5
                        ? () {
                            ref
                                .read(viewPreferencesProvider.notifier)
                                .toggleViewType();
                          }
                        : null,
                  ),
                  // Size Toggle
                  IconButton(
                    icon: Icon(
                      Icons.text_fields,
                      size: switch (currentSize) {
                        ViewSize.small => 18.0,
                        ViewSize.normal => 24.0,
                        ViewSize.large => 30.0,
                      },
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: _opacityAnimation.value > 0.5
                        ? () {
                            ref
                                .read(viewPreferencesProvider.notifier)
                                .cycleSize();
                          }
                        : null,
                    constraints: const BoxConstraints(
                      minWidth: 48.0,
                      minHeight: 48.0,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
