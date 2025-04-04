import 'package:dart_mappable/dart_mappable.dart'; // Added
import 'package:hive_ce/hive.dart';

part 'card_synergy.mapper.dart'; // Added

@MappableClass(caseStyle: CaseStyle.camelCase) // Added
@HiveType(typeId: 8)
class CardSynergy with CardSynergyMappable {
  // Added mixin
  @HiveField(0)
  final String sourceCardId;
  @HiveField(1)
  final String targetCardId;
  @HiveField(2)
  final String synergyType; // Consider making this SynergyType enum
  @HiveField(3)
  final double synergyStrength;
  @HiveField(4)
  final String? description;

  const CardSynergy({
    // Changed to standard constructor
    required this.sourceCardId,
    required this.targetCardId,
    required this.synergyType,
    required this.synergyStrength,
    this.description,
  });

  // fromJson factory removed
}

@MappableEnum() // Added
enum SynergyType {
  element,
  ability,
  job,
  name,
  category,
  combo,
}
