// lib/features/cards/presentation/pages/card_details_page.dart
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:fftcg_companion/core/widgets/cached_card_image.dart';
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
    return Stack(
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Center(
                child: Hero(
                  tag: 'card_${card.productId}',
                  child: Material(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(3),
                    clipBehavior: Clip.antiAlias,
                    child: AspectRatio(
                      aspectRatio: 223 / 311,
                      child: CachedCardImage(
                        imageUrl:
                            card.getImageUrl(quality: models.ImageQuality.high),
                        fit: BoxFit.cover,
                        borderRadius: BorderRadius.circular(3),
                        placeholder: Image.asset(
                          'assets/images/card-back.jpeg',
                          fit: BoxFit.cover,
                        ),
                        animate: false,
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
                    Text(
                      card.name,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
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
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: MediaQuery.of(context).size.width * (311 / 223),
              pinned: true,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Hero(
                  tag: 'card_${card.productId}',
                  child: Material(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(3),
                    clipBehavior: Clip.antiAlias,
                    child: AspectRatio(
                      aspectRatio: 223 / 311,
                      child: CachedCardImage(
                        imageUrl: card.getImageUrl(
                            quality: models.ImageQuality.medium),
                        fit: BoxFit.cover,
                        borderRadius: BorderRadius.circular(3),
                        placeholder: Image.asset(
                          'assets/images/card-back.jpeg',
                          fit: BoxFit.cover,
                        ),
                        animate: false,
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
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.name,
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                    ),
                    const SizedBox(height: 24),
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
            _buildInfoRow('Card Number', card.primaryCardNumber, textTheme),
            const Divider(height: 24),
            if (card.elements.isNotEmpty)
              _buildInfoRow('Element', card.elements.join(', '), textTheme),
            if (card.cardType != null)
              _buildInfoRow('Type', card.cardType!, textTheme),
            if (card.cost != null)
              _buildInfoRow('Cost', card.cost.toString(), textTheme),
            if (card.job != null) _buildInfoRow('Job', card.job!, textTheme),
            if (card.category != null)
              _buildInfoRow('Category', card.category!, textTheme),
            if (card.rarity != null)
              _buildInfoRow('Rarity', card.rarity!, textTheme),
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
              Text(
                card.description!,
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
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
