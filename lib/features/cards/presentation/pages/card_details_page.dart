// lib/features/cards/presentation/pages/card_details_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

  Widget _buildWideLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Center(
            child: Hero(
              tag: 'card_${card.productId}',
              child: AspectRatio(
                aspectRatio: 223 / 311,
                child: CachedNetworkImage(
                  imageUrl: card.highResUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Icon(Icons.broken_image),
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
                ).animate().fadeIn(delay: 300.ms, duration: 500.ms),
                const SizedBox(height: 16),
                _buildInfoSection(context),
                const SizedBox(height: 16),
                _buildExtendedDataSection(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNormalLayout(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: MediaQuery.of(context).size.width * (311 / 223),
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(card.name)
                .animate()
                .fadeIn(delay: 300.ms, duration: 500.ms),
            background: Hero(
              tag: 'card_${card.productId}',
              child: CachedNetworkImage(
                imageUrl: card.highResUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Icon(Icons.broken_image),
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
                _buildInfoSection(context),
                const SizedBox(height: 16),
                _buildExtendedDataSection(context),
              ],
            ).animate().fadeIn(delay: 200.ms).slideX(),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Card Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            _buildInfoRow('Card Number', card.primaryCardNumber),
            _buildInfoRow('Group ID', card.groupId.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildExtendedDataSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Card Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            ...card.extendedData.entries.map(
              (entry) => _buildInfoRow(
                entry.value.displayName,
                entry.value.value,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }
}
