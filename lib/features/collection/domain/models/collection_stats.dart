// lib/features/collection/domain/models/collection_stats.dart

import 'package:dart_mappable/dart_mappable.dart'; // Added

part 'collection_stats.mapper.dart'; // Added

@MappableClass() // Added
class CollectionStats with CollectionStatsMappable {
  // Added mixin
  final int totalCards;
  final int uniqueCards;
  final Map<String, int> elementDistribution;
  final Map<String, int> typeDistribution;
  final Map<String, int> rarityDistribution;
  final Map<String, int> setDistribution;
  final int foilCount;
  final int normalCount;
  final double collectionCompleteness;
  final double estimatedValue;

  const CollectionStats({
    // Changed to standard constructor
    required this.totalCards,
    required this.uniqueCards,
    required this.elementDistribution,
    required this.typeDistribution,
    required this.rarityDistribution,
    required this.setDistribution,
    required this.foilCount,
    required this.normalCount,
    required this.collectionCompleteness,
    required this.estimatedValue,
  });

  // fromJson factory removed - handled by dart_mappable generator
}
