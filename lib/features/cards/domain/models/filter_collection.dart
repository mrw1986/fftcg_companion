import 'package:dart_mappable/dart_mappable.dart'; // Added

part 'filter_collection.mapper.dart'; // Added

@MappableClass(caseStyle: CaseStyle.camelCase) // Added
class FilterCollection with FilterCollectionMappable {
  // Added mixin
  final List<String> cardType;
  final List<String> category;
  final List<String> cost;
  final List<String> elements;
  final List<String> power;
  final List<String> rarity;
  final List<String> set;

  const FilterCollection({
    // Changed to standard constructor
    required this.cardType,
    required this.category,
    required this.cost,
    required this.elements,
    required this.power,
    required this.rarity,
    required this.set,
  });

  // fromJson factory removed

  // Keep the empty factory
  factory FilterCollection.empty() => const FilterCollection(
        cardType: [],
        category: [],
        cost: [],
        elements: [],
        power: [],
        rarity: [],
        set: [],
      );
}

@MappableClass(caseStyle: CaseStyle.camelCase) // Added
class FilterCollectionCache with FilterCollectionCacheMappable {
  // Added mixin
  final FilterCollection filters;
  final DateTime lastUpdated;

  const FilterCollectionCache({
    // Changed to standard constructor
    required this.filters,
    required this.lastUpdated,
  });

  // fromJson factory removed
}
