// lib/features/cards/presentation/pages/card_details_page.dart
import 'dart:math';
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:fftcg_companion/core/widgets/cached_card_image.dart';
import 'package:fftcg_companion/features/cards/presentation/widgets/card_description_text.dart';
import 'package:flutter/material.dart';
import 'package:fftcg_companion/features/models.dart' as models;

class CardDetailsPage extends StatelessWidget {
  final models.Card card;

  const CardDetailsPage({
    super.key,
    required this.card,
  });

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      body: isWideScreen
          ? _buildWideLayout(context)
          : _buildNormalLayout(context),
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

  Widget _buildWideLayout(BuildContext context) {
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
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(top: topPadding),
                  child: Hero(
                    tag: 'card_${card.productId}',
                    child: Container(
                      width: cardWidth,
                      height: maxCardHeight,
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(9.0),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: CachedCardImage(
                        imageUrl: card.getBestImageUrl(),
                        fit: BoxFit.contain,
                        borderRadius: BorderRadius.circular(9.0),
                        placeholder: Image.asset(
                          'assets/images/card-back.jpeg',
                          fit: BoxFit.contain,
                        ),
                        useProgressiveLoading: false,
                        onImageError: () {
                          talker.error(
                              'Failed to load high-res image for card: ${card.productId}');
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildExtendedDataSection(context),
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

  Widget _buildNormalLayout(BuildContext context) {
    // Calculate the maximum height to ensure the card is fully visible
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    // Use a percentage of screen height to ensure the card is visible on all devices
    // including foldable phones with unusual aspect ratios
    final maxCardHeight = screenHeight * 0.55;

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
              flexibleSpace: FlexibleSpaceBar(
                background: Hero(
                  tag: 'card_${card.productId}',
                  child: Padding(
                    padding: EdgeInsets.only(top: topPadding),
                    child: Center(
                      child: Container(
                        width: cardWidth,
                        height: cardHeight,
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(9.0),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: CachedCardImage(
                          imageUrl: card.getBestImageUrl(),
                          fit: BoxFit.contain,
                          borderRadius: BorderRadius.circular(9.0),
                          placeholder: Image.asset(
                            'assets/images/card-back.jpeg',
                            fit: BoxFit.contain,
                          ),
                          useProgressiveLoading: false,
                          onImageError: () {
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
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildExtendedDataSection(context),
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

  Widget _buildExtendedDataSection(BuildContext context) {
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
