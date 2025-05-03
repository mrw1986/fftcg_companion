// lib/features/collection/domain/providers/collection_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart'; // Import Hive
import 'package:fftcg_companion/core/utils/logger.dart'; // Import Logger
import '../models/collection_item.dart';
import '../../data/repositories/collection_repository.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/card_cache_provider.dart';
import 'package:fftcg_companion/features/models.dart' as models;
// Import the correct collection filter provider for shared card filters
import 'package:fftcg_companion/features/collection/presentation/providers/collection_filter_provider.dart';
// Keep import for the CardFilters model
// Import favorite/wishlist providers
import 'package:fftcg_companion/features/cards/presentation/providers/favorites_provider.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/wishlist_provider.dart';

/// Repository provider
final collectionRepositoryProvider = Provider<CollectionRepository>((ref) {
  return CollectionRepository();
});

/// User's collection provider
final userCollectionProvider =
    AsyncNotifierProvider<UserCollectionNotifier, List<CollectionItem>>(() {
  return UserCollectionNotifier();
});

/// Collection notifier
class UserCollectionNotifier extends AsyncNotifier<List<CollectionItem>> {
  @override
  Future<List<CollectionItem>> build() async {
    final authState = ref.watch(authNotifierProvider);

    if (authState.isAuthenticated || authState.isAnonymous) {
      final repository = ref.read(collectionRepositoryProvider);
      return repository.getUserCollection(authState.user!.uid);
    }

    return [];
  }

  /// Refresh the collection
  Future<void> refreshCollection() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authState = ref.read(authNotifierProvider);

      if (authState.isAuthenticated || authState.isAnonymous) {
        final repository = ref.read(collectionRepositoryProvider);
        return repository.getUserCollection(authState.user!.uid);
      }

      return [];
    });
  }

  /// Get a specific card from the collection
  Future<CollectionItem?> getCardFromCollection(String cardId) async {
    final authState = ref.read(authNotifierProvider);

    if (authState.isAuthenticated || authState.isAnonymous) {
      final repository = ref.read(collectionRepositoryProvider);
      return repository.getUserCard(authState.user!.uid, cardId);
    }

    return null;
  }

  /// Add or update a card in the collection
  Future<void> addOrUpdateCard({
    required String cardId,
    int? regularQty,
    int? foilQty,
    Map<String, CardCondition>? condition,
    Map<String, PurchaseInfo>? purchaseInfo,
    Map<String, GradingInfo>? gradingInfo,
  }) async {
    final authState = ref.read(authNotifierProvider);

    if (authState.isAuthenticated || authState.isAnonymous) {
      final repository = ref.read(collectionRepositoryProvider);
      await repository.addOrUpdateCard(
        userId: authState.user!.uid,
        cardId: cardId,
        regularQty: regularQty,
        foilQty: foilQty,
        condition: condition,
        purchaseInfo: purchaseInfo,
        gradingInfo: gradingInfo,
      );

      // Refresh collection
      refreshCollection();

      // Refresh collection stats
      ref.invalidate(collectionStatsProvider);
    }
  }

  /// Remove a card from the collection
  Future<void> removeCard(String documentId) async {
    final repository = ref.read(collectionRepositoryProvider);
    await repository.removeCard(documentId);

    // Refresh collection
    refreshCollection();

    // Refresh collection stats
    ref.invalidate(collectionStatsProvider);
  }
}

/// Collection statistics provider
final collectionStatsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final authState = ref.watch(authNotifierProvider);

  if (authState.isAuthenticated || authState.isAnonymous) {
    final repository = ref.read(collectionRepositoryProvider);
    return repository.getUserCollectionStats(authState.user!.uid);
  }

  return {
    'totalCards': 0,
    'uniqueCards': 0,
    'regularCards': 0,
    'foilCards': 0,
  };
});

// --- Refactored collectionSpecificFilterProvider to NotifierProvider ---
final collectionSpecificFilterProvider =
    NotifierProvider<CollectionSpecificFilterNotifier, Map<String, dynamic>>(
        () {
  return CollectionSpecificFilterNotifier();
});

class CollectionSpecificFilterNotifier extends Notifier<Map<String, dynamic>> {
  static const _boxName = 'settings';
  static const _filtersKey = 'collection_specific_filters'; // Unique key

  late Box _box;

  @override
  Map<String, dynamic> build() {
    _openBox();
    final savedData = _box.get(_filtersKey);
    if (savedData is Map) {
      talker.debug('Loading saved collection-specific filters from Hive.');
      // Ensure keys are strings and values are dynamic
      return Map<String, dynamic>.from(savedData);
    }
    talker.debug(
        'No saved collection-specific filters found, using defaults (empty map).');
    return {}; // Default to empty map
  }

  void _openBox() {
    try {
      if (!Hive.isBoxOpen(_boxName)) {
        Hive.openBox(_boxName); // Consider async open if issues arise
      }
      _box = Hive.box(_boxName);
    } catch (e, stack) {
      talker.error(
          'Error opening Hive box for collection-specific filters', e, stack);
    }
  }

  Future<void> setFilter(String key, dynamic value) async {
    final newState = Map<String, dynamic>.from(state);
    newState[key] = value;
    state = newState;
    await _saveFilters();
  }

  Future<void> removeFilter(String key) async {
    final newState = Map<String, dynamic>.from(state);
    if (newState.containsKey(key)) {
      newState.remove(key);
      state = newState;
      await _saveFilters();
    }
  }

  Future<void> clearFilters() async {
    if (state.isNotEmpty) {
      state = {};
      await _saveFilters();
    }
  }

  Future<void> _saveFilters() async {
    try {
      if (!_box.isOpen) _openBox();
      await _box.put(_filtersKey, state);
      talker.debug('Saved collection-specific filters to Hive: $state');
    } catch (e, stack) {
      talker.error(
          'Error saving collection-specific filters to Hive', e, stack);
    }
  }
}
// --- End Refactor ---

/// Collection sort provider
final collectionSortProvider = StateProvider<String>((ref) {
  return 'lastModified';
});

/// Filtered collection provider
final filteredCollectionProvider = Provider<List<CollectionItem>>((ref) {
  final collectionAsync = ref.watch(userCollectionProvider);
  // Watch the collection-specific filters (NOW A NOTIFIER)
  final collectionSpecificFilters = ref.watch(collectionSpecificFilterProvider);
  // Watch the shared card filters (renamed provider)
  final cardsFilter = ref.watch(collectionFilterProvider);
  final sort = ref.watch(collectionSortProvider);
  final cardCacheAsync = ref.watch(collectionCardCacheProvider);
  // Watch favorite/wishlist providers
  final favorites = ref.watch(favoritesProvider);
  final wishlist = ref.watch(wishlistProvider);

  return collectionAsync.when(
    data: (collection) {
      // Apply filters
      var filtered = collection;

      // Parse sort field and direction
      bool sortDescending = sort.contains(':desc');
      String sortField = sort.split(':').first;

      // Apply collection-specific filters using collectionSpecificFilters
      if (collectionSpecificFilters.containsKey('type')) {
        if (collectionSpecificFilters['type'] == 'regular') {
          filtered = filtered.where((item) => item.regularQty > 0).toList();
        } else if (collectionSpecificFilters['type'] == 'foil') {
          filtered = filtered.where((item) => item.foilQty > 0).toList();
        }
      }

      if (collectionSpecificFilters.containsKey('graded') &&
          collectionSpecificFilters['graded'] == true) {
        filtered =
            filtered.where((item) => item.gradingInfo.isNotEmpty).toList();

        if (collectionSpecificFilters.containsKey('gradingCompany')) {
          filtered = filtered.where((item) {
            return item.gradingInfo.values.any(
              (info) =>
                  info.company.name ==
                  collectionSpecificFilters['gradingCompany'],
            );
          }).toList();
        }
      }

      // Apply card filters if we have cached cards
      if (filtered.isNotEmpty &&
          cardCacheAsync.hasValue &&
          cardCacheAsync.value != null) {
        final cards = cardCacheAsync.value!;
        final cardMap = {
          for (var card in cards) card.productId.toString(): card
        };

        // Filter by elements
        if (cardsFilter.elements.isNotEmpty) {
          filtered = filtered.where((item) {
            final card = cardMap[item.cardId];
            if (card == null) return false;

            for (final element in cardsFilter.elements) {
              if (card.elements.contains(element)) {
                return true;
              }
            }
            return false;
          }).toList();
        }

        // Filter by types
        if (cardsFilter.types.isNotEmpty) {
          filtered = filtered.where((item) {
            final card = cardMap[item.cardId];
            if (card == null) return false;

            return card.cardType != null &&
                cardsFilter.types.contains(card.cardType);
          }).toList();
        }

        // Filter by rarities
        if (cardsFilter.rarities.isNotEmpty) {
          filtered = filtered.where((item) {
            final card = cardMap[item.cardId];
            if (card == null) return false;

            return card.rarity != null &&
                cardsFilter.rarities.contains(card.rarity);
          }).toList();
        }

        // Filter by categories
        if (cardsFilter.categories.isNotEmpty) {
          filtered = filtered.where((item) {
            final card = cardMap[item.cardId];
            if (card == null) return false;

            return card.category != null &&
                cardsFilter.categories.contains(card.category);
          }).toList();
        }

        // Filter by sets
        if (cardsFilter.set.isNotEmpty) {
          filtered = filtered.where((item) {
            final card = cardMap[item.cardId];
            if (card == null) return false;

            // Check if any of the card's sets are in the filter sets
            for (final setId in card.set) {
              if (cardsFilter.set.contains(setId)) {
                return true;
              }
            }
            return false;
          }).toList();
        }

        // Filter by cost
        if (cardsFilter.minCost != null || cardsFilter.maxCost != null) {
          filtered = filtered.where((item) {
            final card = cardMap[item.cardId];
            if (card == null) return false;

            final cost = card.cost;
            if (cost == null) return false;

            if (cardsFilter.minCost != null && cost < cardsFilter.minCost!) {
              return false;
            }

            if (cardsFilter.maxCost != null && cost > cardsFilter.maxCost!) {
              return false;
            }

            return true;
          }).toList();
        }

        // Filter by power
        if (cardsFilter.minPower != null || cardsFilter.maxPower != null) {
          filtered = filtered.where((item) {
            final card = cardMap[item.cardId];
            if (card == null) return false;

            final power = card.power;
            if (power == null) return false;

            if (cardsFilter.minPower != null && power < cardsFilter.minPower!) {
              return false;
            }

            if (cardsFilter.maxPower != null && power > cardsFilter.maxPower!) {
              return false;
            }

            return true;
          }).toList();
        }

        // Filter by sealed products
        if (!cardsFilter.showSealedProducts) {
          filtered = filtered.where((item) {
            final card = cardMap[item.cardId];
            if (card == null) return true; // Keep items without cards

            return card.cardType != 'Sealed Product';
          }).toList();
        }
      }

      // --- Apply Favorite/Wishlist Filters ---
      if (cardsFilter.showFavoritesOnly) {
        filtered =
            filtered.where((item) => favorites.contains(item.cardId)).toList();
      }
      if (cardsFilter.showWishlistOnly) {
        filtered =
            filtered.where((item) => wishlist.contains(item.cardId)).toList();
      }
      // --- End Favorite/Wishlist Filters ---

      // Apply sorting
      if (filtered.isNotEmpty) {
        filtered = List<CollectionItem>.from(filtered); // Create a mutable copy

        filtered.sort((a, b) {
          switch (sortField) {
            case 'cardId':
              return sortDescending
                  ? b.cardId.compareTo(a.cardId)
                  : a.cardId.compareTo(b.cardId);
            case 'regularQty':
              // Sort by quantity, then by cardId for stable sorting
              final qtyCompare = sortDescending
                  ? a.regularQty.compareTo(b.regularQty)
                  : b.regularQty.compareTo(a.regularQty);
              return qtyCompare != 0
                  ? qtyCompare
                  : a.cardId.compareTo(b.cardId);
            case 'foilQty':
              final qtyCompare = sortDescending
                  ? a.foilQty.compareTo(b.foilQty)
                  : b.foilQty.compareTo(a.foilQty);
              return qtyCompare != 0
                  ? qtyCompare
                  : a.cardId.compareTo(b.cardId);
            case 'totalQty':
              final totalA = a.regularQty + a.foilQty;
              final totalB = b.regularQty + b.foilQty;
              final qtyCompare = sortDescending
                  ? totalA.compareTo(totalB)
                  : totalB.compareTo(totalA);
              return qtyCompare != 0
                  ? qtyCompare
                  : a.cardId.compareTo(b.cardId);
            case 'marketPrice':
            case 'lowPrice':
            case 'midPrice':
            case 'highPrice':
              // Price sorting will be implemented later
              return sortDescending
                  ? a.lastModified.compareTo(b.lastModified)
                  : b.lastModified.compareTo(a.lastModified);
            case 'lastModified':
            default:
              return sortDescending
                  ? a.lastModified.compareTo(b.lastModified)
                  : b.lastModified.compareTo(a.lastModified);
          }
        });
      }

      return filtered;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Search query provider
final collectionSearchQueryProvider = StateProvider<String>((ref) {
  return '';
});

/// Card cache provider for collection search
final collectionCardCacheProvider =
    FutureProvider<List<models.Card>>((ref) async {
  final cardCache = ref.watch(cardCacheNotifierProvider).valueOrNull;
  if (cardCache == null) {
    return [];
  }

  return await cardCache.getCachedCards();
});

/// Searched collection provider
final searchedCollectionProvider = Provider<List<CollectionItem>>((ref) {
  final filteredCollection = ref.watch(filteredCollectionProvider);
  final searchQuery = ref.watch(collectionSearchQueryProvider);
  final cardCacheAsync = ref.watch(collectionCardCacheProvider);

  if (searchQuery.isEmpty) {
    return filteredCollection;
  }

  final query = searchQuery.toLowerCase();

  return cardCacheAsync.when(
    data: (cards) {
      // Use the cached cards for more sophisticated search
      final cardMap = {for (var card in cards) card.productId.toString(): card};

      return filteredCollection.where((item) {
        // Find the card in the cache
        final card = cardMap[item.cardId];

        // If we can't find the card, just check the cardId
        if (card == null) {
          return item.cardId.toLowerCase().contains(query);
        }

        // Otherwise, check the card name, number, and other properties
        return card.name.toLowerCase().contains(query) ||
            (card.displayNumber?.toLowerCase().contains(query) ?? false) ||
            card.searchTerms.any((term) => term.contains(query)) ||
            card.matchesSearchTerm(query);
      }).toList();
    },
    loading: () {
      // Simple search while cards are loading
      return filteredCollection.where((item) {
        return item.cardId.toLowerCase().contains(query);
      }).toList();
    },
    error: (_, __) {
      // Fallback to simple search on error
      return filteredCollection.where((item) {
        return item.cardId.toLowerCase().contains(query);
      }).toList();
    },
  );
});
