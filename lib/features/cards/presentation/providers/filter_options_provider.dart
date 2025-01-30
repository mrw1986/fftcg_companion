// lib/features/cards/presentation/providers/filter_options_provider.dart

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fftcg_companion/features/repositories.dart'; // Update this import
import 'package:fftcg_companion/features/cards/domain/models/card_filter_options.dart';
import 'package:fftcg_companion/core/utils/logger.dart';

part 'filter_options_provider.g.dart';
part 'filter_options_provider.freezed.dart';

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

  static const _opusPattern =
      r'^(?:OP|Opus\s*)?([0-9]+|(?:X{1,3}|IX|IV|V?I{1,3}))$';
  final _opusRegex = RegExp(_opusPattern, caseSensitive: false);

  @override
  Future<CardFilterOptions> build() async {
    try {
      await _prefetchSetInfo();

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
        rarities: const {'C', 'R', 'H', 'L', 'S', 'P'},
        sets: _setInfo.keys.toSet(),
        costRange: (0, 10),
        powerRange: (0, 10000),
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
        sets: {},
        rarities: {'C', 'R', 'H', 'L', 'S', 'P'},
        costRange: (0, 10),
        powerRange: (0, 10000),
      );
    }
  }

  Future<void> _prefetchSetInfo() async {
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final groupsSnapshot = await firestoreService.groupsCollection
          .get()
          .timeout(const Duration(seconds: 10));

      if (!groupsSnapshot.docs.any((doc) => doc.exists)) {
        talker.warning('No set information found in Firestore');
        return;
      }

      for (final doc in groupsSnapshot.docs) {
        if (!doc.exists) continue;

        final data = doc.data();
        final setId = doc.id;

        // Use null-safe accessors
        final name = data['name'] as String? ?? setId;
        final abbreviation =
            data['abbreviation'] as String?; // Keep as nullable
        final publishedOn = data['publishedOn'] as String?;
        final publishedDate = publishedOn?.isNotEmpty == true
            ? DateTime.parse(publishedOn!)
            : DateTime(1900);

        final (category, sortOrder) = _categorizeSet(
          setId: setId,
          name: name,
          abbreviation:
              abbreviation ?? setId, // Provide default for categorization
        );

        _setInfo[setId] = SetInfo(
          id: setId,
          name: name,
          abbreviation: abbreviation, // Can now be null
          category: category,
          publishedDate: publishedDate,
          sortOrder: sortOrder,
        );
      }

      talker.debug('Cached ${_setInfo.length} set records');
    } catch (e, stack) {
      talker.error('Error prefetching set information', e, stack);
      // Don't rethrow - allow fallback to default options
    }
  }

  (SetCategory, int) _categorizeSet({
    required String setId,
    required String name,
    required String abbreviation, // Now guaranteed to be non-null
  }) {
    // Check for promotional sets first
    if (name.contains('Promo') ||
        abbreviation == 'PR' ||
        name.contains('Promotional')) {
      return (SetCategory.promotional, 1000);
    }

    // Check for Opus sets
    final opusMatch = _opusRegex.firstMatch(abbreviation);
    if (opusMatch != null) {
      final opusNum = _parseOpusNumber(opusMatch.group(1)!);
      return (SetCategory.opus, 2000 + opusNum);
    }

    // Handle numeric-only abbreviations
    if (RegExp(r'^\d+$').hasMatch(abbreviation)) {
      return (SetCategory.collection, 3000 + int.parse(abbreviation));
    }

    // Collections and special sets
    if (name.contains('Collection') ||
        name.contains('Deck') ||
        name.contains('Starter') ||
        name.contains('Heroes') ||
        name.contains('Crystal') ||
        name.contains('Hidden')) {
      return (SetCategory.collection, 3500);
    }

    // Default to collection category
    return (SetCategory.collection, 3999);
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
