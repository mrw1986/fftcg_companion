// lib/features/cards/presentation/pages/cards_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/cards_provider.dart';
import 'package:fftcg_companion/features/models.dart' as models;
import 'package:fftcg_companion/features/cards/presentation/widgets/filter_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:fftcg_companion/features/cards/domain/models/card_filters.dart';

final viewModeProvider =
    StateProvider<bool>((ref) => true); // true = grid, false = list

class CardsPage extends ConsumerStatefulWidget {
  const CardsPage({super.key});

  @override
  ConsumerState<CardsPage> createState() => _CardsPageState();
}

class _CardsPageState extends ConsumerState<CardsPage> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      ref.read(cardsNotifierProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewMode = ref.watch(viewModeProvider);
    final cards = ref.watch(cardsNotifierProvider);
    final searchResults = _isSearching && _searchController.text.isNotEmpty
        ? ref.watch(cardSearchProvider(_searchController.text))
        : null;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search cards...',
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _isSearching = false);
                    },
                  ),
                ),
                onChanged: (value) {
                  setState(() {}); // Trigger rebuild to update search results
                },
              )
            : const Text('Cards'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.cancel : Icons.search),
            onPressed: () {
              setState(() => _isSearching = !_isSearching);
              if (!_isSearching) _searchController.clear();
            },
          ),
          IconButton(
            icon: Icon(viewMode ? Icons.grid_view : Icons.view_list),
            onPressed: () {
              ref.read(viewModeProvider.notifier).state = !viewMode;
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () async {
              final result = await showDialog<CardFilters>(
                context: context,
                builder: (context) => const FilterDialog(),
              );
              if (result != null) {
                // Apply filters
                ref.read(cardsNotifierProvider.notifier).applyFilters(result);
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(cardsNotifierProvider.notifier).refresh(),
        child: cards.when(
          data: (cardList) {
            final displayedCards = searchResults?.value ?? cardList;

            if (displayedCards.isEmpty) {
              return const Center(
                child: Text('No cards found'),
              );
            }

            return viewMode
                ? GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: displayedCards.length,
                    itemBuilder: (context, index) {
                      return CardGridItem(card: displayedCards[index]);
                    },
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: displayedCards.length,
                    itemBuilder: (context, index) {
                      return CardListItem(card: displayedCards[index]);
                    },
                  );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => ErrorView(
            message: error.toString(),
            onRetry: () => ref.refresh(cardsNotifierProvider),
          ),
        ),
      ),
    );
  }
}

class CardGridItem extends StatelessWidget {
  final models.Card card;

  const CardGridItem({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context.push(
            '/cards/${card.productId}', 
            extra: card,
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Image.network(
                card.lowResUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(Icons.broken_image),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    card.primaryCardNumber,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CardListItem extends StatelessWidget {
  final models.Card card;

  const CardListItem({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: SizedBox(
        width: 40,
        height: 56,
        child: Image.network(
          card.lowResUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Icon(Icons.broken_image),
            );
          },
        ),
      ),
      title: Text(card.name),
      subtitle: Text(card.primaryCardNumber),
      onTap: () {
        context.push(
          '/cards/${card.productId}',
          extra: card,
        );
      },
    );
  }
}

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
