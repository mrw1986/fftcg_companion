// lib/features/cards/domain/models/card.dart

import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:fftcg_companion/core/utils/soundex.dart';
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
    String? cardType,
    String? category,
    int? cost,
    String? description,
    @Default([]) List<String> elements,
    String? job,
    String? number,
    int? power,
    String? rarity,
    @Default([]) List<String> cardNumbers,
    @Default([]) List<String> searchTerms,
  }) = _Card;

  factory Card.fromJson(Map<String, dynamic> json) => _$CardFromJson(json);

  factory Card.fromFirestore(Map<String, dynamic> data) {
    final name = data['name'] as String? ?? '';
    final number = data['number'] as String?;
    final cardNumbers =
        (data['cardNumbers'] as List?)?.map((e) => e.toString()).toList() ?? [];
    // Get search terms array
    final searchTerms =
        (data['searchTerms'] as List?)?.map((e) => e.toString()).toList() ?? [];

    return Card(
      productId: data['productId'] as int? ?? 0,
      name: name,
      cleanName: data['cleanName'] as String? ?? '',
      fullResUrl: data['fullResUrl'] as String? ?? '',
      highResUrl: data['highResUrl'] as String? ?? '',
      lowResUrl: data['lowResUrl'] as String? ?? '',
      lastUpdated: (data['lastUpdated'] is Timestamp)
          ? (data['lastUpdated'] as Timestamp).toDate()
          : null,
      groupId: data['groupId'] as int? ?? 0,
      isNonCard: data['isNonCard'] as bool? ?? false,
      cardType: data['cardType'] as String?,
      category: data['category'] as String?,
      cost: data['cost'] as int?,
      description: data['description'] as String?,
      elements:
          (data['elements'] as List?)?.map((e) => e.toString()).toList() ?? [],
      job: data['job'] as String?,
      number: number,
      power: data['power'] as int?,
      rarity: data['rarity'] as String?,
      cardNumbers: cardNumbers,
      searchTerms: searchTerms,
    );
  }

  Map<String, dynamic> toFirestore() {
    final Map<String, dynamic> data = {
      'productId': productId,
      'name': name,
      'cleanName': cleanName,
      'fullResUrl': fullResUrl,
      'highResUrl': highResUrl,
      'lowResUrl': lowResUrl,
      'groupId': groupId,
      'isNonCard': isNonCard,
      'elements': elements,
      'cardNumbers': cardNumbers,
      'searchTerms': searchTerms,
    };

    // Add optional fields
    if (lastUpdated != null) {
      data['lastUpdated'] = Timestamp.fromDate(lastUpdated!);
    }
    if (cardType != null) data['cardType'] = cardType;
    if (category != null) data['category'] = category;
    if (cost != null) data['cost'] = cost;
    if (description != null) data['description'] = description;
    if (job != null) data['job'] = job;
    if (number != null) data['number'] = number;
    if (power != null) data['power'] = power;
    if (rarity != null) data['rarity'] = rarity;

    return data;
  }

  // Helper methods for card properties
  bool get hasElement => elements.isNotEmpty;
  bool get hasMultipleElements => elements.length > 1;
  bool get isForward => cardType?.toLowerCase() == 'forward';
  bool get isBackup => cardType?.toLowerCase() == 'backup';
  bool get isSummon => cardType?.toLowerCase() == 'summon';
  bool get isMonster => cardType?.toLowerCase() == 'monster';

  // Display helpers
  String? get displayNumber => isNonCard ? null : number;
  String get displayRarity => isNonCard ? 'Sealed Product' : (rarity ?? '');

  // Rarity helpers
  bool get isCommon => !isNonCard && rarity?.toLowerCase() == 'c';
  bool get isRare => !isNonCard && rarity?.toLowerCase() == 'r';
  bool get isHeroic => !isNonCard && rarity?.toLowerCase() == 'h';
  bool get isLegendary => !isNonCard && rarity?.toLowerCase() == 'l';
  bool get isSpecial => !isNonCard && rarity?.toLowerCase() == 's';
  bool get isPromo => !isNonCard && rarity?.toLowerCase() == 'p';

  // Compare cards for sorting
  int compareByNumber(Card other) {
    // If either card is a non-card, sort them to the end
    if (isNonCard && other.isNonCard) return 0;
    if (isNonCard) return 1;
    if (other.isNonCard) return -1;

    // Compare by number field if both are actual cards
    final thisNum = number ?? '';
    final otherNum = other.number ?? '';

    // Extract numeric parts for comparison
    final thisMatch = RegExp(r'(\d+)').firstMatch(thisNum);
    final otherMatch = RegExp(r'(\d+)').firstMatch(otherNum);

    if (thisMatch != null && otherMatch != null) {
      final thisNumeric = int.parse(thisMatch.group(1)!);
      final otherNumeric = int.parse(otherMatch.group(1)!);
      return thisNumeric.compareTo(otherNumeric);
    }

    // Fall back to string comparison if no numbers found
    return thisNum.compareTo(otherNum);
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
    return searchTerms.contains(searchTerm) ||
        searchTerms.any((token) => token.startsWith(searchTerm)) ||
        searchTerms.contains(SoundexUtil.generate(searchTerm));
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
