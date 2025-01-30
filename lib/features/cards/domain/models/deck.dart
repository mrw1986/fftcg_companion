import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive.dart';

part 'deck.freezed.dart';
part 'deck.g.dart';

@freezed
@HiveType(typeId: 6)
class Deck with _$Deck {
  const factory Deck({
    @HiveField(0) required String id,
    @HiveField(1) required String name,
    @HiveField(2) required String userId,
    @HiveField(3) required Map<String, int> cards, // cardId -> quantity
    @HiveField(4) String? description,
    @HiveField(5) DateTime? lastModified,
    @HiveField(6) @Default(false) bool isPublic,
    @HiveField(7) @Default([]) List<String> tags,
  }) = _Deck;

  factory Deck.fromJson(Map<String, dynamic> json) => _$DeckFromJson(json);
}

@freezed
class DeckValidation with _$DeckValidation {
  const factory DeckValidation({
    required bool isValid,
    @Default([]) List<String> errors,
    @Default([]) List<String> warnings,
    required Map<String, int> elementCount,
    required Map<String, int> costDistribution,
    required double averageCost,
  }) = _DeckValidation;
}
