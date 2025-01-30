// lib/features/cards/domain/models/card.dart

import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'card.freezed.dart';
part 'card.g.dart';

@freezed
class Card with _$Card {
  const Card._();

  const factory Card({
    required int productId,
    required String name,
    required String cleanName,
    required String fullResUrl,
    required String highResUrl,
    required String lowResUrl,
    DateTime? lastUpdated,
    required int groupId,
    @Default(false) bool isNonCard,
    required List<String> cardNumbers,
    required String primaryCardNumber,
    String? cardType,
    String? category,
    int? cost,
    String? description,
    @Default([]) List<String> elements,
    String? job,
    String? number,
    int? power,
    String? rarity,
  }) = _Card;

  factory Card.fromJson(Map<String, dynamic> json) => _$CardFromJson(json);

  factory Card.fromFirestore(Map<String, dynamic> data) {
    return Card(
      productId: data['productId'] as int? ?? 0,
      name: data['name'] as String? ?? '',
      cleanName: data['cleanName'] as String? ?? '',
      fullResUrl: data['fullResUrl'] as String? ?? '',
      highResUrl: data['highResUrl'] as String? ?? '',
      lowResUrl: data['lowResUrl'] as String? ?? '',
      lastUpdated: (data['lastUpdated'] is Timestamp)
          ? (data['lastUpdated'] as Timestamp).toDate()
          : null,
      groupId: data['groupId'] as int? ?? 0,
      isNonCard: data['isNonCard'] as bool? ?? false,
      cardNumbers:
          (data['cardNumbers'] as List?)?.map((e) => e.toString()).toList() ??
              [],
      primaryCardNumber: data['primaryCardNumber'] as String? ?? '',
      cardType: data['cardType'] as String?,
      category: data['category'] as String?,
      cost: data['cost'] as int?,
      description: data['description'] as String?,
      elements:
          (data['elements'] as List?)?.map((e) => e.toString()).toList() ?? [],
      job: data['job'] as String?,
      number: data['number'] as String?,
      power: data['power'] as int?,
      rarity: data['rarity'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'name': name,
      'cleanName': cleanName,
      'fullResUrl': fullResUrl,
      'highResUrl': highResUrl,
      'lowResUrl': lowResUrl,
      if (lastUpdated != null) 'lastUpdated': Timestamp.fromDate(lastUpdated!),
      'groupId': groupId,
      'isNonCard': isNonCard,
      'cardNumbers': cardNumbers,
      'primaryCardNumber': primaryCardNumber,
      if (cardType != null) 'cardType': cardType,
      if (category != null) 'category': category,
      if (cost != null) 'cost': cost,
      if (description != null) 'description': description,
      'elements': elements,
      if (job != null) 'job': job,
      if (number != null) 'number': number,
      if (power != null) 'power': power,
      if (rarity != null) 'rarity': rarity,
    };
  }

  // Helper methods for card properties
  bool get hasElement => elements.isNotEmpty;
  bool get hasMultipleElements => elements.length > 1;
  bool get isForward => cardType?.toLowerCase() == 'forward';
  bool get isBackup => cardType?.toLowerCase() == 'backup';
  bool get isSummon => cardType?.toLowerCase() == 'summon';
  bool get isMonster => cardType?.toLowerCase() == 'monster';

  // Rarity helpers
  bool get isCommon => rarity?.toLowerCase() == 'c';
  bool get isRare => rarity?.toLowerCase() == 'r';
  bool get isHeroic => rarity?.toLowerCase() == 'h';
  bool get isLegendary => rarity?.toLowerCase() == 'l';
  bool get isSpecial => rarity?.toLowerCase() == 's';
  bool get isPromo => rarity?.toLowerCase() == 'p';

  // Compare cards for sorting
  int compareByNumber(Card other) {
    return primaryCardNumber.compareTo(other.primaryCardNumber);
  }

  int compareByCost(Card other) {
    if (cost == null && other.cost == null) return 0;
    if (cost == null) return -1;
    if (other.cost == null) return 1;
    return cost!.compareTo(other.cost!);
  }

  int compareByName(Card other) {
    return cleanName.compareTo(other.cleanName);
  }

  int compareByPower(Card other) {
    if (power == null && other.power == null) return 0;
    if (power == null) return -1;
    if (other.power == null) return 1;
    return power!.compareTo(other.power!);
  }

  // Search helpers
  bool matchesSearchTerm(String term) {
    final searchTerm = term.toLowerCase().trim();
    return name.toLowerCase().contains(searchTerm) ||
        cleanName.toLowerCase().contains(searchTerm) ||
        cardNumbers
            .any((number) => number.toLowerCase().contains(searchTerm)) ||
        (description?.toLowerCase().contains(searchTerm) ?? false);
  }

  bool matchesElement(String element) {
    return elements.any((e) => e.toLowerCase() == element.toLowerCase());
  }

  bool matchesType(String type) {
    return cardType?.toLowerCase() == type.toLowerCase();
  }

  bool matchesRarity(String rarityToMatch) {
    return rarity?.toLowerCase() == rarityToMatch.toLowerCase();
  }

  bool matchesCostRange(int? minCost, int? maxCost) {
    if (cost == null) return false;
    if (minCost != null && cost! < minCost) return false;
    if (maxCost != null && cost! > maxCost) return false;
    return true;
  }

  bool matchesPowerRange(int? minPower, int? maxPower) {
    if (power == null) return false;
    if (minPower != null && power! < minPower) return false;
    if (maxPower != null && power! > maxPower) return false;
    return true;
  }

  // URL helpers
  String getImageUrl({ImageQuality quality = ImageQuality.high}) {
    final url = switch (quality) {
      ImageQuality.low => lowResUrl,
      ImageQuality.medium => highResUrl,
      ImageQuality.high => fullResUrl,
    };

    talker.debug('Getting image URL: $url for quality: $quality');
    return url;
  }
}

enum ImageQuality {
  low,
  medium,
  high,
}
