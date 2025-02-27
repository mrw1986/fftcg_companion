// lib/features/cards/presentation/providers/filter_options_provider.dart

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fftcg_companion/features/repositories.dart';
import 'package:fftcg_companion/features/cards/domain/models/card_filter_options.dart';
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:fftcg_companion/core/providers/card_cache_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'filter_options_provider.g.dart';
part 'filter_options_provider.freezed.dart';

// Generated provider
final cardCacheProvider = cardCacheNotifierProvider;

enum SetCategory {
  promotional,
  collection,
  opus;

  String get displayName => switch (this) {
        SetCategory.promotional => 'Promotional Sets',
        SetCategory.collection => 'Collections & Decks',
        SetCategory.opus => 'Opus Sets',
      };
}

@freezed
class SetInfo with _$SetInfo {
  const factory SetInfo({
    required String id,
    required String name,
    String? abbreviation, // Changed to nullable
    required SetCategory category,
    required DateTime publishedDate,
    required int sortOrder,
  }) = _SetInfo;
}

@Riverpod(keepAlive: true)
class FilterOptionsNotifier extends _$FilterOptionsNotifier {
  final Map<String, SetInfo> _setInfo = {};

  @override
  Future<CardFilterOptions> build() async {
    try {
      // Try to get cached filter options first
      final cardCache = await ref.read(cardCacheProvider.future);
      final cachedOptions = await cardCache.getCachedFilterOptions();

      if (cachedOptions != null) {
        talker.debug('Using cached filter options');
        _setInfo.clear();
        _setInfo.addAll(Map<String, SetInfo>.from(
          (cachedOptions['setInfo'] as Map).map(
            (key, value) => MapEntry(
              key as String,
              SetInfo(
                id: value['id'] as String,
                name: value['name'] as String,
                abbreviation: value['abbreviation'] as String?,
                category: SetCategory.values.firstWhere(
                  (e) => e.name == value['category'] as String,
                ),
                publishedDate: DateTime.parse(value['publishedDate'] as String),
                sortOrder: value['sortOrder'] as int,
              ),
            ),
          ),
        ));
        _costRange = (
          cachedOptions['minCost'] as int,
          cachedOptions['maxCost'] as int,
        );
        _powerRange = (
          cachedOptions['minPower'] as int,
          cachedOptions['maxPower'] as int,
        );

        return CardFilterOptions(
          elements: Set<String>.from(cachedOptions['elements'] as List),
          types: Set<String>.from(cachedOptions['types'] as List),
          rarities: Set<String>.from(cachedOptions['rarities'] as List),
          set: _setInfo.keys.toSet(),
          costRange: _costRange,
          powerRange: _powerRange,
        );
      }

      // If no cache or cache expired, fetch from Firestore
      await _prefetchSetInfo();

      // Cache the new filter options
      final cache = await ref.read(cardCacheProvider.future);
      await cache.cacheFilterOptions({
        'elements': const [
          'Fire',
          'Ice',
          'Wind',
          'Earth',
          'Lightning',
          'Water',
          'Light',
          'Dark'
        ],
        'types': const ['Forward', 'Backup', 'Summon', 'Monster'],
        'rarities': const [
          'Common',
          'Rare',
          'Hero',
          'Legend',
          'Starter',
          'Promo'
        ],
        'setInfo': _setInfo.map((key, value) => MapEntry(key, {
              'id': value.id,
              'name': value.name,
              'abbreviation': value.abbreviation,
              'category': value.category.name,
              'publishedDate': value.publishedDate.toIso8601String(),
              'sortOrder': value.sortOrder,
            })),
        'minCost': _costRange.$1,
        'maxCost': _costRange.$2,
        'minPower': _powerRange.$1,
        'maxPower': _powerRange.$2,
      });

      return CardFilterOptions(
        elements: const {
          'Fire',
          'Ice',
          'Wind',
          'Earth',
          'Lightning',
          'Water',
          'Light',
          'Dark'
        },
        types: const {'Forward', 'Backup', 'Summon', 'Monster'},
        rarities: const {
          'Common',
          'Rare',
          'Hero',
          'Legend',
          'Starter',
          'Promo'
        },
        set: _setInfo.keys.toSet(),
        costRange: _costRange,
        powerRange: _powerRange,
      );
    } catch (e, stack) {
      talker.error('Error building filter options', e, stack);
      // Return default options on error
      return const CardFilterOptions(
        elements: {
          'Fire',
          'Ice',
          'Wind',
          'Earth',
          'Lightning',
          'Water',
          'Light',
          'Dark'
        },
        types: {'Forward', 'Backup', 'Summon', 'Monster'},
        set: {},
        rarities: {'Common', 'Rare', 'Hero', 'Legend', 'Starter', 'Promo'},
        costRange: (0, 10),
        powerRange: (0, 10000),
      );
    }
  }

  (int, int) _costRange = (0, 10);
  (int, int) _powerRange = (0, 10000);

  Future<void> _prefetchSetInfo() async {
    try {
      final firestoreService = ref.read(firestoreServiceProvider);

      // Get all cards to determine ranges and sets
      final cardsSnapshot = await firestoreService.cardsCollection.get();
      if (cardsSnapshot.docs.isEmpty) {
        talker.warning('No cards found in Firestore');
        return;
      }

      // Find min/max cost and power from all cards
      int? minCost, maxCost;
      int? minPower, maxPower;
      final allSets = <String>{};
      final groupIdToSets = <int, Set<String>>{};

      for (final doc in cardsSnapshot.docs) {
        final data = doc.data();

        // Get cost range
        final cost = data['cost'] as int?;
        if (cost != null) {
          minCost = minCost == null
              ? cost
              : cost < minCost
                  ? cost
                  : minCost;
          maxCost = maxCost == null
              ? cost
              : cost > maxCost
                  ? cost
                  : maxCost;
        }

        // Get power range
        final power = data['power'] as int?;
        if (power != null) {
          minPower = minPower == null
              ? power
              : power < minPower
                  ? power
                  : minPower;
          maxPower = maxPower == null
              ? power
              : power > maxPower
                  ? power
                  : maxPower;
        }

        // Get sets and map them to groupId
        final cardSets =
            (data['set'] as List?)?.map((e) => e.toString()).toList() ?? [];
        allSets.addAll(cardSets);

        // Store the groupId to sets mapping
        final groupId = data['groupId'] as int?;
        if (groupId != null && cardSets.isNotEmpty) {
          groupIdToSets.putIfAbsent(groupId, () => <String>{}).addAll(cardSets);
        }
      }

      // Update ranges
      if (minCost != null && maxCost != null) {
        _costRange = (minCost, maxCost);
      }
      if (minPower != null && maxPower != null) {
        // Round power range to nearest 1000
        _powerRange = (
          (minPower / 1000).floor() * 1000,
          ((maxPower / 1000).ceil() + 1) * 1000
        );
      }

      // Fetch group information to get published dates
      final groupsSnapshot = await firestoreService.groupsCollection.get();
      final groupInfo = <int, Map<String, dynamic>>{};

      for (final doc in groupsSnapshot.docs) {
        final data = doc.data();
        final groupId = data['groupId'] as int?;
        if (groupId != null) {
          groupInfo[groupId] = data;
        }
      }

      // Process all sets with their group information
      for (final setName in allSets) {
        // Find the groupId for this set
        int? setGroupId;
        for (final entry in groupIdToSets.entries) {
          if (entry.value.contains(setName)) {
            setGroupId = entry.key;
            break;
          }
        }

        // Get category and sort order
        final (category, sortOrder) = _categorizeSet(
          setId: setName,
          name: setName,
          abbreviation: setName,
        );

        // Get published date from group info if available
        DateTime publishedDate = DateTime(1900);
        if (setGroupId != null && groupInfo.containsKey(setGroupId)) {
          final group = groupInfo[setGroupId]!;
          final publishedOn = group['publishedOn'];

          if (publishedOn is Timestamp) {
            publishedDate = publishedOn.toDate();
          } else if (publishedOn is String) {
            try {
              publishedDate = DateTime.parse(publishedOn);
            } catch (e) {
              talker.warning('Failed to parse publishedOn date: $publishedOn');
            }
          }
        }

        _setInfo[setName] = SetInfo(
          id: setName,
          name: setName,
          abbreviation: null,
          category: category,
          publishedDate: publishedDate,
          sortOrder: sortOrder,
        );
      }

      talker.debug(
          'Cached ${_setInfo.length} set records with publication dates');
    } catch (e, stack) {
      talker.error('Error prefetching set information', e, stack);
      // Don't rethrow - allow fallback to default options
    }
  }

  (SetCategory, int) _categorizeSet({
    required String setId,
    required String name,
    required String abbreviation,
  }) {
    // Check for Opus sets first - this includes both "Opus X" format and just "Opus"
    if (name.startsWith('Opus')) {
      final opusMatch = RegExp(r'Opus\s*(\w+)?').firstMatch(name);
      if (opusMatch != null) {
        final opusNum = opusMatch.group(1) != null
            ? _parseOpusNumber(opusMatch.group(1)!)
            : 0; // For just "Opus"
        return (SetCategory.opus, 2000 + opusNum);
      }
    }

    // Check for promotional sets
    if (name.toLowerCase().contains('promo') ||
        name.toLowerCase().contains('promotional')) {
      return (SetCategory.promotional, 1000);
    }

    // Collections and special sets - these are explicitly identified by keywords
    if (name.toLowerCase().contains('collection') ||
        name.toLowerCase().contains('deck') ||
        name.toLowerCase().contains('starter')) {
      return (SetCategory.collection, 3500);
    }

    // Check for core sets that should be categorized as Opus
    // These include sets like "Crystal Dominion", "Beyond Destiny", etc.
    // that are core sets but don't have "Opus" in their name
    final coreSetNames = [
      'Crystal Dominion',
      'Beyond Destiny',
      'Dawn of Heroes',
      'Emissaries of Light',
      'From Nightmares',
      'Hidden Hope',
      'Hidden Legends',
      'Hidden Trials',
      'Rebellion\'s Call',
      'Resurgence of Power',
      'Tears of the Planet',
    ];

    if (coreSetNames.any(
        (coreName) => name.toLowerCase().contains(coreName.toLowerCase()))) {
      return (SetCategory.opus, 3000);
    }

    // Any other sets that don't match the above categories
    // should be categorized as Opus sets by default
    return (SetCategory.opus, 3000);
  }

  int _parseOpusNumber(String input) {
    // First check if it's a simple number
    if (RegExp(r'^\d+$').hasMatch(input)) {
      return int.parse(input);
    }

    // Roman numeral mapping
    final romanNumerals = {
      'I': 1,
      'II': 2,
      'III': 3,
      'IV': 4,
      'V': 5,
      'VI': 6,
      'VII': 7,
      'VIII': 8,
      'IX': 9,
      'X': 10,
      'XI': 11,
      'XII': 12,
      'XIII': 13,
      'XIV': 14,
      'XV': 15,
    };

    // Try parsing as roman numeral
    final upper = input.toUpperCase();
    return romanNumerals[upper] ?? 999;
  }

  Map<SetCategory, List<String>> getGroupedSets() {
    final grouped = <SetCategory, List<String>>{};

    for (final category in SetCategory.values) {
      final setsInCategory = _setInfo.entries
          .where((e) => e.value.category == category)
          .map((e) => e.key)
          .toList();

      // Sort sets within each category
      setsInCategory.sort((a, b) {
        final setA = _setInfo[a]!;
        final setB = _setInfo[b]!;

        // First by sort order
        final orderCompare = setA.sortOrder.compareTo(setB.sortOrder);
        if (orderCompare != 0) return orderCompare;

        // Then by publication date
        final dateCompare = setA.publishedDate.compareTo(setB.publishedDate);
        if (dateCompare != 0) return dateCompare;

        // Finally by name
        return setA.name.compareTo(setB.name);
      });

      grouped[category] = setsInCategory;
    }

    return grouped;
  }

  // Helper methods
  String getSetName(String setId) => _setInfo[setId]?.name ?? setId;
  SetCategory? getSetCategory(String setId) => _setInfo[setId]?.category;
  int getSetOrder(String setId) => _setInfo[setId]?.sortOrder ?? 9999;
}
