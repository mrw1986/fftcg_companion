import 'package:freezed_annotation/freezed_annotation.dart';

part 'card_filters.freezed.dart';
part 'card_filters.g.dart';

@freezed
class CardFilters with _$CardFilters {
  const factory CardFilters({
    // Elements in FFTCG: Fire, Ice, Wind, Earth, Lightning, Water
    @Default({}) Set<String> elements,

    // Types: Forward, Backup, Summon, Monster
    @Default({}) Set<String> types,

    // Categories
    @Default({}) Set<String> categories,

    // Jobs
    @Default({}) Set<String> jobs,

    // Cost: 0-12
    int? minCost,
    int? maxCost,

    // Power: varies by card
    int? minPower,
    int? maxPower,

    // Set/Opus numbers
    @Default({}) Set<String> sets,

    // Rarity: C, R, H, L, S, P
    @Default({}) Set<String> rarities,

    // Special filters
    bool? isNormalOnly,
    bool? isFoilOnly,

    // Text search
    String? searchText,
  }) = _CardFilters;

  factory CardFilters.fromJson(Map<String, dynamic> json) =>
      _$CardFiltersFromJson(json);
}
