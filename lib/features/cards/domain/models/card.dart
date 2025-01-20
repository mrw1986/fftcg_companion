// lib/features/cards/domain/models/card.dart

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'card.freezed.dart';
part 'card.g.dart';

@freezed
class Card with _$Card {
  @HiveType(typeId: 0)
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

  factory Card.fromJson(Map<String, dynamic> json) => _$CardFromJson(json);
}

@freezed
class ExtendedData with _$ExtendedData {
  @HiveType(typeId: 1)
  const factory ExtendedData({
    @HiveField(0) @Default('N/A') String name,
    @HiveField(1) @Default('N/A') String displayName,
    @HiveField(2) @Default(null) dynamic value,
  }) = _ExtendedData;

  factory ExtendedData.fromJson(Map<String, dynamic> json) =>
      _$ExtendedDataFromJson(json);
}

// Helper extension to safely handle ExtendedData values
// In lib/features/cards/domain/models/card.dart

extension ExtendedDataHelpers on ExtendedData {
  List<String> getArrayValue() {
    if (value is List) {
      return List<String>.from(value as List);
    }
    return [];
  }

  String getStringValue() {
    return value?.toString() ?? 'N/A';
  }

  int? getIntValue() {
    if (value is num) {
      return (value as num).toInt();
    }
    return null;
  }
}

// Helper extension to access common card properties
extension CardHelpers on Card {
  List<String> get elements {
    return extendedData['Elements']?.getArrayValue() ?? [];
  }

  String get cardType {
    return extendedData['CardType']?.getStringValue() ?? 'N/A';
  }

  int? get cost {
    return extendedData['Cost']?.getIntValue();
  }

  int? get power {
    return extendedData['Power']?.getIntValue();
  }
}
