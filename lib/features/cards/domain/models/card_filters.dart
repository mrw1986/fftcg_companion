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
    @Default({}) Set<String> sets,
    @Default({}) Set<String> rarities,
    bool? isNormalOnly,
    bool? isFoilOnly,
    String? searchText,
    // Add sorting fields
    String? sortField,
    @Default(false) bool sortDescending,
  }) = _CardFilters;

  factory CardFilters.fromJson(Map<String, dynamic> json) =>
      _$CardFiltersFromJson(json);
}
