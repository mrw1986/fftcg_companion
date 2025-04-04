import 'package:dart_mappable/dart_mappable.dart'; // Added
import 'package:hive_ce/hive.dart';

part 'deck.mapper.dart'; // Added

@MappableClass(caseStyle: CaseStyle.camelCase) // Added
@HiveType(typeId: 6)
class Deck with DeckMappable {
  // Added mixin
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String userId;
  @HiveField(3)
  final Map<String, int> cards; // cardId -> quantity
  @HiveField(4)
  final String? description;
  @HiveField(5)
  final DateTime? lastModified;
  @HiveField(6)
  final bool isPublic;
  @HiveField(7)
  final List<String> tags;

  const Deck({
    // Changed to standard constructor
    required this.id,
    required this.name,
    required this.userId,
    required this.cards,
    this.description,
    this.lastModified,
    this.isPublic = false, // Default value
    this.tags = const [], // Default value
  });

  // fromJson factory removed
}

@MappableClass(caseStyle: CaseStyle.camelCase) // Added
class DeckValidation with DeckValidationMappable {
  // Added mixin
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final Map<String, int> elementCount;
  final Map<String, int> costDistribution;
  final double averageCost;

  const DeckValidation({
    // Changed to standard constructor
    required this.isValid,
    this.errors = const [], // Default value
    this.warnings = const [], // Default value
    required this.elementCount,
    required this.costDistribution,
    required this.averageCost,
  });
}
