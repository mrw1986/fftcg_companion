// lib/features/cards/domain/models/card_filter_options.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'card_filter_options.freezed.dart';
part 'card_filter_options.g.dart';

@freezed
class CardFilterOptions with _$CardFilterOptions {
  const factory CardFilterOptions({
    required Set<String> elements,
    required Set<String> types,
    required Set<String> sets,
    required Set<String> rarities,
    required (int, int) costRange,
    required (int, int) powerRange,
  }) = _CardFilterOptions;

  factory CardFilterOptions.fromJson(Map<String, dynamic> json) =>
      _$CardFilterOptionsFromJson(json);
}
