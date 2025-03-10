// lib/features/cards/presentation/pages/card_details_page.dart
import 'dart:math';
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:fftcg_companion/features/cards/presentation/widgets/card_description_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fftcg_companion/features/models.dart' as models;
import 'package:fftcg_companion/features/cards/presentation/providers/filtered_search_provider.dart';
import 'package:go_router/go_router.dart';

class CardDetailsPage extends ConsumerStatefulWidget {
  final models.Card initialCard;

  const CardDetailsPage({
    super.key,
    required this.initialCard,
  });

  @override
  ConsumerState<CardDetailsPage> createState() => _CardDetailsPageState();
}

class _CardDetailsPageState extends ConsumerState<CardDetailsPage> {
  late PageController _pageController;
  late models.Card _currentCard;
  List<models.Card> _allCards = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isFavorite = false;
  bool _isInWishlist = false;

  @override
  void initState() {
    super.initState();
    _currentCard = widget.initialCard;
    _pageController = PageController();
    _initializeCardList();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initializeCardList() async {
    // Get the current filtered card list
    final filteredCards = await ref.read(filteredSearchNotifierProvider.future);

    if (mounted) {
      setState(() {
        _allCards = filteredCards;
        // Find the index of the current card in the list
        _currentIndex = _allCards
            .indexWhere((card) => card.productId == _currentCard.productId);
        if (_currentIndex < 0) _currentIndex = 0;

        // Initialize the page controller to the current index
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _pageController.hasClients) {
            _pageController.jumpToPage(_currentIndex);
          }
        });

        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 900;

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: PageView.builder(
        controller: _pageController,
        itemCount: _allCards.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
            _currentCard = _allCards[index];
          });
        },
        itemBuilder: (context, index) {
          final card = _allCards[index];
          return isWideScreen
              ? _buildWideLayout(context, card)
              : _buildNormalLayout(context, card);
        },
      ),
    );
  }

  Widget _buildEnhancedBackButton(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Material(
          color: Colors.transparent,
          child: IconButton(
            iconSize: 26,
            padding: const EdgeInsets.all(12),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black54,
              shadowColor: Colors.black26,
              elevation: 4,
            ),
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationOverlay(BuildContext context) {
    return Stack(
      children: [
        // Previous button - positioned on left side
        if (_currentIndex > 0)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    borderRadius: BorderRadius.circular(40),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_left,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Next button - positioned on right side
        if (_currentIndex < _allCards.length - 1)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    borderRadius: BorderRadius.circular(40),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, models.Card card) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Add to Collection button
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add to Collection'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: () {
              context.push('/collection/add?cardId=${card.productId}');
            },
          ),
          const SizedBox(width: 12),

          // Favorite button
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.star : Icons.star_border,
              color: _isFavorite ? Colors.amber : null,
            ),
            tooltip: _isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
            onPressed: () {
              setState(() {
                _isFavorite = !_isFavorite;
              });
              // This is a placeholder - no actual functionality yet
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isFavorite
                        ? 'Added to favorites'
                        : 'Removed from favorites',
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),

          // Wishlist button
          IconButton(
            icon: Icon(
              _isInWishlist ? Icons.bookmark : Icons.bookmark_border,
              color: _isInWishlist ? colorScheme.tertiary : null,
            ),
            tooltip: _isInWishlist ? 'Remove from Wishlist' : 'Add to Wishlist',
            onPressed: () {
              setState(() {
                _isInWishlist = !_isInWishlist;
              });
              // This is a placeholder - no actual functionality yet
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isInWishlist
                        ? 'Added to wishlist'
                        : 'Removed from wishlist',
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context, models.Card card) {
    // Calculate dimensions for wide layout
    final screenHeight = MediaQuery.of(context).size.height;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    // Use a percentage of screen height to ensure the card is fully visible
    final maxCardHeight = screenHeight * 0.8;

    // Calculate card width based on the standard card aspect ratio (223/311)
    final cardWidth = maxCardHeight * (223 / 311);

    // Add padding to move the card down from the status bar
    final topPadding = statusBarHeight + 16.0;

    return Stack(
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: topPadding),
                            child: SizedBox(
                              width: cardWidth,
                              height: maxCardHeight,
                              child: Container(
                                decoration: BoxDecoration(
                                  color:
                                      Theme.of(context).scaffoldBackgroundColor,
                                  borderRadius: BorderRadius.circular(16.0),
                                  image: DecorationImage(
                                    image: NetworkImage(
                                        card.getBestImageUrl() ?? ''),
                                    fit: BoxFit.contain,
                                    onError: (_, __) {
                                      talker.error(
                                          'Failed to load high-res image for card: ${card.productId}');
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      _buildActionButtons(context, card),
                    ],
                  ),
                  // Add navigation overlay on top of the card image
                  _buildNavigationOverlay(context),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildExtendedDataSection(context, card),
                  ],
                ),
              ),
            ),
          ],
        ),
        _buildEnhancedBackButton(context),
      ],
    );
  }

  Widget _buildNormalLayout(BuildContext context, models.Card card) {
    // Calculate the maximum height to ensure the card is fully visible
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    // Use a percentage of screen height to ensure the card is visible on all devices
    // including foldable phones with unusual aspect ratios
    final maxCardHeight =
        screenHeight * 0.45; // Reduced to make room for action buttons

    // Calculate card width based on the standard card aspect ratio (223/311)
    // but constrained by the maximum height
    final cardWidth = min(screenWidth, maxCardHeight * (223 / 311));

    // Recalculate the height based on the constrained width to maintain aspect ratio
    final cardHeight = cardWidth * (311 / 223);

    // Add padding to move the card down from the status bar
    final topPadding = statusBarHeight + 16.0;

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: cardHeight + topPadding,
              pinned: true,
              automaticallyImplyLeading: false,
              flexibleSpace: Stack(
                children: [
                  FlexibleSpaceBar(
                    background: Padding(
                      padding: EdgeInsets.only(top: topPadding),
                      child: Center(
                        child: SizedBox(
                          width: cardWidth,
                          height: cardHeight,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(16.0),
                              image: DecorationImage(
                                image:
                                    NetworkImage(card.getBestImageUrl() ?? ''),
                                fit: BoxFit.contain,
                                onError: (_, __) {
                                  talker.error(
                                      'Failed to load high-res image for card: ${card.productId}');
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Add navigation overlay on top of the card image
                  _buildNavigationOverlay(context),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: _buildActionButtons(context, card),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildExtendedDataSection(context, card),
                  ],
                ),
              ),
            ),
          ],
        ),
        _buildEnhancedBackButton(context),
      ],
    );
  }

  Widget _buildExtendedDataSection(BuildContext context, models.Card card) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              card.name,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            // Card Number
            if (card.displayNumber != null) ...[
              _buildInfoRow('Card Number', card.displayNumber!, textTheme),
              const Divider(height: 24),
            ],
            // Rarity
            _buildInfoRow('Rarity', card.displayRarity, textTheme),
            // Card Type
            if (card.cardType != null)
              _buildInfoRow('Type', card.cardType!, textTheme),
            // Job
            if (card.job != null) _buildInfoRow('Job', card.job!, textTheme),
            // Elements
            if (card.elements.isNotEmpty)
              _buildInfoRow('Element(s)', card.elements.join(', '), textTheme),
            // Cost
            if (card.cost != null)
              _buildInfoRow('Cost', card.cost.toString(), textTheme),
            // Power
            if (card.power != null)
              _buildInfoRow('Power', card.power.toString(), textTheme),
            // Category
            if (card.displayCategory != null)
              _buildInfoRow('Category', card.displayCategory!, textTheme),
            // Set
            if (card.set.isNotEmpty)
              _buildInfoRow('Set', card.set.join(' · '), textTheme),
            // Description (if exists)
            if (card.description != null) ...[
              const Divider(height: 24),
              Text(
                'Description',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              if (card.description != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: CardDescriptionText(
                    text: card.description!,
                    baseStyle: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
