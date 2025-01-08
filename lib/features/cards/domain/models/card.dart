// lib/features/cards/domain/models/card.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'card.freezed.dart';
part 'card.g.dart';

@freezed
@HiveType(typeId: 0)
class Card with _$Card {
  const factory Card({
    @HiveField(0) required int productId,
    @HiveField(1) required String name,
    @HiveField(2) required String cleanName,
    @HiveField(3) required String highResUrl,
    @HiveField(4) required String lowResUrl,
    @HiveField(5) required DateTime lastUpdated,
    @HiveField(6) required int groupId,
    @HiveField(7) required bool isNonCard,
    @HiveField(8) required List<String> cardNumbers,
    @HiveField(9) required String primaryCardNumber,
    @HiveField(10) required Map<String, ExtendedData> extendedData,
    @HiveField(11) @Default({}) Set<String> synergies,
    @HiveField(12) @Default({}) Set<String> keywords,
    @HiveField(13) String? rulesText,
    @HiveField(14) @Default(false) bool isFullArt,
    @HiveField(15) String? artistName,
  }) = _Card;

  factory Card.fromJson(Map<String, dynamic> json) => _$CardFromJson(json);
}

@freezed
@HiveType(typeId: 1)
class ExtendedData with _$ExtendedData {
  const factory ExtendedData({
    @HiveField(0) required String name,
    @HiveField(1) required String displayName,
    @HiveField(2) required String value,
  }) = _ExtendedData;

  factory ExtendedData.fromJson(Map<String, dynamic> json) =>
      _$ExtendedDataFromJson(json);
}
