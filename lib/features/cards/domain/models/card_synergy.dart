import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive.dart';

part 'card_synergy.freezed.dart';
part 'card_synergy.g.dart';

@freezed
@HiveType(typeId: 8)
class CardSynergy with _$CardSynergy {
  const factory CardSynergy({
    @HiveField(0) required String sourceCardId,
    @HiveField(1) required String targetCardId,
    @HiveField(2) required String synergyType,
    @HiveField(3) required double synergyStrength,
    @HiveField(4) String? description,
  }) = _CardSynergy;

  factory CardSynergy.fromJson(Map<String, dynamic> json) =>
      _$CardSynergyFromJson(json);
}

enum SynergyType {
  element,
  ability,
  job,
  name,
  category,
  combo,
}
