// lib/features/cards/domain/models/card.dart

import 'package:dart_mappable/dart_mappable.dart'; // Added
import 'package:cloud_firestore/cloud_firestore.dart';

part 'card.mapper.dart'; // Added

@MappableClass(caseStyle: CaseStyle.camelCase) // Added
class Card with CardMappable {
  // Added mixin
  final int productId;
  final String name;
  final String cleanName;
  final String fullResUrl;
  final String highResUrl;
  final String lowResUrl;
  final DateTime? lastUpdated;
  final int groupId;
  final bool isNonCard;
  final String? cardType;
  final String? category;
  final List<String> categories;
  final int? cost;
  final String? description;
  final List<String> elements;
  final String? job;
  final String? number;
  final int? power;
  final String? rarity;
  final List<String> cardNumbers;
  final List<String> searchTerms;
  final List<String> set;
  final String? fullCardNumber;

  const Card({
    // Changed to standard constructor
    required this.productId,
    required this.name,
    required this.cleanName,
    required this.fullResUrl,
    required this.highResUrl,
    required this.lowResUrl,
    this.lastUpdated,
    required this.groupId,
    this.isNonCard = false, // Default value
    this.cardType,
    this.category,
    this.categories = const [], // Default value
    this.cost,
    this.description,
    this.elements = const [], // Default value
    this.job,
    this.number,
    this.power,
    this.rarity,
    this.cardNumbers = const [], // Default value
    this.searchTerms = const [], // Default value
    this.set = const [], // Default value
    this.fullCardNumber,
  });

  // fromJson factory removed

  // Keep custom Firestore factory
  factory Card.fromFirestore(Map<String, dynamic> data) {
    final name = data['name'] as String? ?? '';
    final number = data['number'] as String?;
    final cardNumbers =
        (data['cardNumbers'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final searchTerms =
        (data['searchTerms'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final categories =
        (data['categories'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final fullCardNumber = data['fullCardNumber'] as String? ??
        (cardNumbers.isNotEmpty ? cardNumbers.join('/') : number);

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
      categories: categories,
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
      set: (data['set'] as List?)?.map((e) => e.toString()).toList() ?? [],
      fullCardNumber: fullCardNumber,
    );
  }

  // Keep custom Firestore method
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
      'set': set,
      'categories': categories,
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
    if (fullCardNumber != null) {
      data['fullCardNumber'] = fullCardNumber; // Added missing field
    }

    return data;
  }

  // Helper methods for card properties (Keep as is)
  bool get hasElement => elements.isNotEmpty;
  bool get hasMultipleElements => elements.length > 1;
  bool get isForward => cardType?.toLowerCase() == 'forward';
  bool get isBackup => cardType?.toLowerCase() == 'backup';
  bool get isSummon => cardType?.toLowerCase() == 'summon';
  bool get isMonster => cardType?.toLowerCase() == 'monster';

  // Display helpers (Keep as is)
  String? get displayNumber => isNonCard ? null : (fullCardNumber ?? number);
  String get displayRarity => isNonCard ? 'Sealed Product' : (rarity ?? '');
  String? get displayCategory => category?.replaceAll('&middot;', ' · ');

  // Rarity helpers (Keep as is)
  bool get isCommon => !isNonCard && rarity?.toLowerCase() == 'c';
  bool get isRare => !isNonCard && rarity?.toLowerCase() == 'r';
  bool get isHeroic => !isNonCard && rarity?.toLowerCase() == 'h';
  bool get isLegendary => !isNonCard && rarity?.toLowerCase() == 'l';
  bool get isSpecial => !isNonCard && rarity?.toLowerCase() == 's';
  bool get isPromo => !isNonCard && rarity?.toLowerCase() == 'p';

  // Compare cards for sorting (Keep as is)
  int compareByNumber(Card other) {
    if (isNonCard && other.isNonCard) return 0;
    if (isNonCard) return 1;
    if (other.isNonCard) return -1;

    final thisNum = fullCardNumber ?? number ?? '';
    final otherNum = other.fullCardNumber ?? other.number ?? '';

    final thisParts = thisNum.split('/')[0].split('-');
    final otherParts = otherNum.split('/')[0].split('-');

    if (thisParts.isEmpty || otherParts.isEmpty) {
      return thisNum.compareTo(otherNum);
    }

    final thisIsCrystal = thisParts[0] == 'C';
    final otherIsCrystal = otherParts[0] == 'C';

    if (thisIsCrystal && !otherIsCrystal) return 1;
    if (!thisIsCrystal && otherIsCrystal) return -1;

    if (thisIsCrystal && otherIsCrystal) {
      if (thisParts.length > 1 && otherParts.length > 1) {
        return thisParts[1].compareTo(otherParts[1]);
      }
      return thisNum.compareTo(otherNum);
    }

    final thisFirstIsNumeric = RegExp(r'^\d+$').hasMatch(thisParts[0]);
    final otherFirstIsNumeric = RegExp(r'^\d+$').hasMatch(otherParts[0]);

    if (thisFirstIsNumeric && !otherFirstIsNumeric) return -1;
    if (!thisFirstIsNumeric && otherFirstIsNumeric) return 1;

    final firstPartComparison = thisParts[0].compareTo(otherParts[0]);
    if (firstPartComparison != 0) return firstPartComparison;

    if (thisParts.length > 1 && otherParts.length > 1) {
      final thisSecondNum = int.tryParse(
              RegExp(r'(\d+)').firstMatch(thisParts[1])?.group(1) ?? '') ??
          0;
      final otherSecondNum = int.tryParse(
              RegExp(r'(\d+)').firstMatch(otherParts[1])?.group(1) ?? '') ??
          0;

      final secondPartComparison = thisSecondNum.compareTo(otherSecondNum);
      if (secondPartComparison != 0) return secondPartComparison;

      return thisParts[1].compareTo(otherParts[1]);
    }

    return thisNum.compareTo(otherNum);
  }

  int compareByCost(Card other) {
    if (cost == null && other.cost == null) return 0;
    if (cost == null) return -1;
    if (other.cost == null) return 1;
    return cost!.compareTo(other.cost!);
  }

  int compareByName(Card other) {
    final thisName = cleanName.toLowerCase();
    final otherName = other.cleanName.toLowerCase();

    final nameComparison = thisName.compareTo(otherName);
    if (nameComparison != 0) return nameComparison;

    return compareByNumber(other);
  }

  int compareByPower(Card other) {
    if (power == null && other.power == null) return 0;
    if (power == null) return -1;
    if (other.power == null) return 1;
    return power!.compareTo(other.power!);
  }

  // Search helpers (Keep as is)
  bool matchesSearchTerm(String term) {
    final searchTerm = term.toLowerCase().trim();
    return searchTerms.contains(searchTerm) ||
        searchTerms.any((token) => token.startsWith(searchTerm));
  }

  // URL helpers (Keep as is)
  String? getBestImageUrl() {
    if (fullResUrl.isNotEmpty) {
      return fullResUrl;
    }
    if (highResUrl.isNotEmpty) {
      return highResUrl;
    }
    if (lowResUrl.isNotEmpty) {
      return lowResUrl;
    }
    return null;
  }
}

@MappableEnum() // Added
enum ImageQuality {
  low,
  medium,
  high,
}
