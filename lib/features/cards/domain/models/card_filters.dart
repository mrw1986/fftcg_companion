import 'package:dart_mappable/dart_mappable.dart'; // Added

part 'card_filters.mapper.dart'; // Added

@MappableClass(caseStyle: CaseStyle.camelCase) // Added annotation
class CardFilters with CardFiltersMappable {
  // Added mixin
  final Set<String> elements;
  final Set<String> types;
  final int? minCost;
  final int? maxCost;
  final int? minPower;
  final int? maxPower;
  final Set<String> set;
  final Set<String> categories;
  final Set<String> rarities;
  final bool? isNormalOnly;
  final bool? isFoilOnly;
  final String? searchText;
  final String? sortField;
  final bool sortDescending;
  final bool showSealedProducts;
  final bool showFavoritesOnly; // Added
  final bool showWishlistOnly; // Added

  const CardFilters({
    // Changed to standard constructor
    this.elements = const {}, // Default value
    this.types = const {}, // Default value
    this.minCost,
    this.maxCost,
    this.minPower,
    this.maxPower,
    this.set = const {}, // Default value
    this.categories = const {}, // Default value
    this.rarities = const {}, // Default value
    this.isNormalOnly,
    this.isFoilOnly,
    this.searchText,
    this.sortField,
    this.sortDescending = false, // Default value
    this.showSealedProducts = true, // Default value
    this.showFavoritesOnly = false, // Added default
    this.showWishlistOnly = false, // Added default
  });

  // fromJson factory removed - handled by dart_mappable generator
}
