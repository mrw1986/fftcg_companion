// lib/features/cards/domain/models/card_filter_options.dart

import 'package:dart_mappable/dart_mappable.dart'; // Added

part 'card_filter_options.mapper.dart'; // Added

@MappableClass(caseStyle: CaseStyle.camelCase) // Added
class CardFilterOptions with CardFilterOptionsMappable {
  // Added mixin
  final Set<String> elements;
  final Set<String> types;
  final Set<String> set;
  final Set<String> rarities;
  // Store ranges as List<int> for mappable compatibility
  final List<int> costRange;
  final List<int> powerRange;

  // Getter to access cost range as a tuple
  (int, int) get costRangeTuple => (costRange[0], costRange[1]);
  // Getter to access power range as a tuple
  (int, int) get powerRangeTuple => (powerRange[0], powerRange[1]);

  const CardFilterOptions({
    // Changed to standard constructor
    required this.elements,
    required this.types,
    required this.set,
    required this.rarities,
    required this.costRange,
    required this.powerRange,
  })  : assert(costRange.length == 2, 'costRange must have length 2'),
        assert(powerRange.length == 2, 'powerRange must have length 2');

  // fromJson factory removed
}
