// lib/features/cards/domain/models/card.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';
import 'package:fftcg_companion/core/utils/logger.dart';

part 'card.freezed.dart';
part 'card.g.dart';

@freezed
class Card with _$Card {
  const factory Card({
    @HiveField(0) required int productId,
    @HiveField(1) required String name,
    @HiveField(2) required String cleanName,
    @HiveField(3) @Default('N/A') String highResUrl,
    @HiveField(4) @Default('N/A') String lowResUrl,
    @HiveField(5) required DateTime lastUpdated,
    @HiveField(6) required int groupId,
    @HiveField(7) @Default(false) bool isNonCard,
    @HiveField(8) @Default([]) List<String> cardNumbers,
    @HiveField(9) @Default('N/A') String primaryCardNumber,
    @HiveField(10) @Default({}) Map<String, ExtendedData> extendedData,
    @HiveField(11) @Default('N/A') String fullResUrl,
  }) = _Card;

  factory Card.fromJson(Map<String, dynamic> json) {
    talker.debug('Converting card from JSON: $json');

    final extendedDataMap = json['extendedData'] as Map<String, dynamic>? ?? {};
    final convertedExtendedData = extendedDataMap.map((key, value) {
      talker.debug('Converting extended data: $key -> $value');
      return MapEntry(
          key, ExtendedData.fromJson(value as Map<String, dynamic>));
    });

    json['extendedData'] = convertedExtendedData;

    return _$CardFromJson(json);
  }
}

@freezed
@HiveType(typeId: 1)
class ExtendedData with _$ExtendedData {
  const factory ExtendedData({
    @HiveField(0) @Default('N/A') String name,
    @HiveField(1) @Default('N/A') String displayName,
    @HiveField(2) @Default('N/A') String value,
  }) = _ExtendedData;

  factory ExtendedData.fromJson(Map<String, dynamic> json) =>
      _$ExtendedDataFromJson(json);
}
