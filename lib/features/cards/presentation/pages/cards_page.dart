import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/cards_provider.dart';
import 'package:fftcg_companion/features/repositories.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/view_preferences_provider.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/search_provider.dart';
import 'package:fftcg_companion/features/cards/presentation/widgets/filter_dialog.dart';
import 'package:fftcg_companion/features/cards/presentation/widgets/sort_bottom_sheet.dart';
import 'package:fftcg_companion/features/cards/domain/models/card_filters.dart';
import 'package:fftcg_companion/shared/widgets/loading_indicator.dart';
import 'package:fftcg_companion/features/cards/presentation/widgets/card_search_bar.dart';
import 'package:fftcg_companion/features/cards/presentation/widgets/card_app_bar_actions.dart';
import 'package:fftcg_companion/features/cards/presentation/widgets/card_content.dart';
import 'package:fftcg_companion/features/cards/presentation/widgets/error_view.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/card_content_provider.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/filtered_search_provider.dart';

class CardsPage extends ConsumerStatefulWidget {
  const CardsPage({super.key});

  @override
  ConsumerState<CardsPage> createState() => _CardsPageState();
}

class _CardsPageState extends ConsumerState<CardsPage>
    with SingleTickerProviderStateMixin {
  bool _isSearching = false;
  late AnimationController _fabAnimationController;

  @override
  void initState() {
    super.initState();
    // Cards will be loaded automatically by the provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefetchInitialImages();
    });

    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _prefetchInitialImages() async {
    final cards = ref.read(cardsNotifierProvider).value;
    if (cards != null && cards.isNotEmpty) {
      await ref
          .read(cardRepositoryProvider.notifier)
          .prefetchVisibleCardImages(cards.take(20).toList());
    }
  }

  Future<void> _showFilterDialog() async {
    final result = await showDialog<CardFilters>(
      context: context,
      builder: (context) => const FilterDialog(),
    );
    if (result != null && mounted) {
      talker.debug('Applying filters from dialog: ${result.toString()}');

      // Apply filters to both the cards provider and filtered search provider
      await ref.read(cardsNotifierProvider.notifier).applyFilters(result);

      // No need to explicitly call the filtered search provider as it watches the cards provider
    }
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2), // 0.2 * 255 = 51
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          tween: Tween(begin: 1.0, end: 0.0),
          builder: (context, value, child) => Transform.translate(
            offset: Offset(0, 200 * value),
            child: child,
          ),
          child: const SortBottomSheet(),
        ),
      ),
    );
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
    });

    if (_isSearching) {
      // Don't hide the FAB during search to allow sorting search results
      // _fabAnimationController.forward();

      // Delay focus to allow animation to start
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && _isSearching) {
          FocusScope.of(context).requestFocus(FocusNode());
        }
      });
    } else {
      // Don't need to show the FAB since it's already visible
      // _fabAnimationController.reverse();

      ref.read(cardSearchControllerProvider).clear();
      ref.read(cardSearchQueryProvider.notifier).setQuery('');
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewPrefs = ref.watch(cardViewPreferencesProvider);
    final searchController = ref.watch(cardSearchControllerProvider);
    final searchQuery = ref.watch(cardSearchQueryProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // Use the filtered search provider which combines search and filter functionality
    final filteredSearchResults = ref.watch(filteredSearchProvider);

    // Determine which cards to display - always use the filtered search results
    // which will return filtered cards when search is empty
    Widget cardContentWidget = filteredSearchResults.when(
      data: (cards) {
        if (cards.isEmpty) {
          return Center(
            child: Text(
              searchQuery.isNotEmpty
                  ? 'No cards found for "$searchQuery"'
                  : 'No cards found',
            ),
          );
        }
        return CardContent(
          key: ref.watch(cardContentKeyProvider),
          cards: cards,
          viewPrefs: viewPrefs,
        );
      },
      loading: () => const LoadingIndicator(),
      error: (error, stack) => ErrorView(
        message: error.toString(),
        onRetry: () => ref.refresh(filteredSearchNotifierProvider),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 1,
        title: CardSearchBar(
          controller: searchController,
          isSearching: _isSearching,
          onSearchToggle: _toggleSearch,
        ),
        actions: [
          CardAppBarActions(
            isSearching: _isSearching,
            onSearchToggle: _toggleSearch,
            onFilterTap: _showFilterDialog,
            onSortTap: _showSortBottomSheet,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(cardsNotifierProvider.notifier).refresh(),
        child: cardContentWidget,
      ),
    );
  }
}
