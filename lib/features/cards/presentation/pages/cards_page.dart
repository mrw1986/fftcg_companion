import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/cards_provider.dart';
import 'package:fftcg_companion/features/cards/data/repositories/card_repository.dart';
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

class CardsPage extends ConsumerStatefulWidget {
  const CardsPage({super.key});

  @override
  ConsumerState<CardsPage> createState() => _CardsPageState();
}

class _CardsPageState extends ConsumerState<CardsPage> {
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Cards will be loaded automatically by the provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefetchInitialImages();
    });
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
      ref.read(cardsNotifierProvider.notifier).applyFilters(result);
    }
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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

  @override
  Widget build(BuildContext context) {
    final viewPrefs = ref.watch(viewPreferencesProvider);
    final searchController = ref.watch(searchControllerProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final cards = ref.watch(cardsNotifierProvider);
    final searchResults = _isSearching && searchQuery.isNotEmpty
        ? ref.watch(cardSearchProvider(searchQuery))
        : null;

    return Scaffold(
      appBar: AppBar(
        title: CardSearchBar(
          controller: searchController,
          isSearching: _isSearching,
          onSearchToggle: () {
            setState(() => _isSearching = !_isSearching);
            if (!_isSearching) {
              searchController.clear();
              ref.read(searchQueryProvider.notifier).state = '';
            }
          },
        ),
        actions: [
          CardAppBarActions(
            isSearching: _isSearching,
            onSearchToggle: () {
              setState(() => _isSearching = !_isSearching);
              if (!_isSearching) {
                searchController.clear();
                ref.read(searchQueryProvider.notifier).state = '';
              }
            },
            onFilterTap: _showFilterDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(cardsNotifierProvider.notifier).refresh(),
        child: _isSearching
            ? searchQuery.isEmpty
                ? const SizedBox.shrink()
                : searchResults?.when(
                      data: (searchedCards) {
                        if (searchedCards.isEmpty) {
                          return const Center(
                            child: Text('No cards found'),
                          );
                        }
                        return CardContent(
                          cards: searchedCards,
                          viewPrefs: viewPrefs,
                        );
                      },
                      loading: () => const LoadingIndicator(),
                      error: (error, stack) => ErrorView(
                        message: error.toString(),
                        onRetry: () =>
                            ref.refresh(cardSearchProvider(searchQuery)),
                      ),
                    ) ??
                    const SizedBox.shrink()
            : cards.when(
                data: (cardList) {
                  if (cardList.isEmpty) {
                    return const Center(
                      child: Text('No cards found'),
                    );
                  }
                  return CardContent(
                    cards: cardList,
                    viewPrefs: viewPrefs,
                  );
                },
                loading: () => const LoadingIndicator(),
                error: (error, stack) => ErrorView(
                  message: error.toString(),
                  onRetry: () => ref.refresh(cardsNotifierProvider),
                ),
              ),
      ),
      floatingActionButton: Consumer(
        builder: (context, ref, child) {
          final cardsState = ref.watch(cardsNotifierProvider);
          final colorScheme = Theme.of(context).colorScheme;
          final isLoading = cardsState.isLoading;

          return Stack(
            alignment: Alignment.center,
            children: [
              FloatingActionButton.extended(
                onPressed: isLoading ? null : _showSortBottomSheet,
                icon: const Icon(Icons.sort),
                label: const Text('Sort'),
                tooltip: isLoading ? 'Loading...' : 'Sort cards',
                elevation: isLoading ? 0 : 4,
                backgroundColor: isLoading
                    ? colorScheme.surfaceContainerHighest
                    : colorScheme.primaryContainer,
                foregroundColor: isLoading
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.onPrimaryContainer,
              ),
              if (isLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorScheme.primary,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
