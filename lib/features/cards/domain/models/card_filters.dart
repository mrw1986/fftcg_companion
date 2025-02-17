import 'package:freezed_annotation/freezed_annotation.dart';

part 'card_filters.freezed.dart';
part 'card_filters.g.dart';

@freezed
class CardFilters with _$CardFilters {
  const factory CardFilters({
    @Default({}) Set<String> elements,
    @Default({}) Set<String> types,
    int? minCost,
    int? maxCost,
    int? minPower,
    int? maxPower,
    @Default({}) Set<String> set,
    @Default({}) Set<String> categories,
    @Default({}) Set<String> rarities,
    bool? isNormalOnly,
    bool? isFoilOnly,
    String? searchText,
    // Add sorting fields
    String? sortField,
    @Default(false) bool sortDescending,
    // Add sealed products toggle
    @Default(true) bool showSealedProducts,
  }) = _CardFilters;

  factory CardFilters.fromJson(Map<String, dynamic> json) =>
      _$CardFiltersFromJson(json);
}
