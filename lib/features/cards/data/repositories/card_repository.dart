import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fftcg_companion/core/services/firestore_provider.dart';
import 'package:fftcg_companion/features/models.dart';
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:fftcg_companion/core/providers/card_cache_provider.dart';
import 'package:fftcg_companion/core/widgets/cached_card_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fftcg_companion/core/storage/cache_service.dart';
import 'package:fftcg_companion/core/storage/card_cache_extensions.dart';

part 'card_repository.g.dart';

/// Provides access to card data with caching support
@Riverpod(keepAlive: true)
class CardRepository extends _$CardRepository {
  // Track sync status
  bool _isSyncing = false;
  DateTime? _lastSyncAttempt;

  @override
  FutureOr<List<Card>> build() async {
    try {
      final cache = await ref.watch(cardCacheNotifierProvider.future);
      final cachedCards = await cache.getCachedCards();

      // If we have cached cards, use them immediately
      if (cachedCards.isNotEmpty) {
        // Schedule a background sync if needed
        _scheduleBackgroundSync();
        return cachedCards;
      }

      // If no cached cards, we need to fetch from Firestore
      return _fetchCardsFromFirestore();
    } catch (e, stack) {
      talker.error('Error loading cards', e, stack);
      rethrow;
    }
  }

  Future<List<Card>> _fetchCardsFromFirestore() async {
    final cache = await ref.watch(cardCacheNotifierProvider.future);
    final firestoreService = ref.read(firestoreServiceProvider);

    try {
      // Get metadata to check version
      final metadata = await firestoreService.getMetadata();
      final remoteVersion = metadata['version'] as int? ?? 1;

      // Fetch all cards
      final snapshot = await firestoreService.cardsCollection.get();
      final cards =
          snapshot.docs.map((doc) => Card.fromFirestore(doc.data())).toList();

      // Cache the cards and version
      await cache.cacheCards(cards);

      // Store the version if we have a cache service
      try {
        if (cache is CacheService) {
          await cache.setDataVersion(remoteVersion);
          await cache.setLastSyncTime(DateTime.now());
        }
      } catch (e) {
        // Ignore errors with the cache service
        talker.debug('Error setting data version: $e');
      }

      talker.info('Fetched ${cards.length} cards from Firestore');
      return cards;
    } catch (e, stack) {
      talker.error('Error fetching cards from Firestore', e, stack);
      // Return empty list if fetch fails
      return [];
    }
  }

  void _scheduleBackgroundSync() async {
    // Don't schedule if already syncing or synced recently
    if (_isSyncing ||
        (_lastSyncAttempt != null &&
            DateTime.now().difference(_lastSyncAttempt!).inMinutes < 30)) {
      return;
    }

    // Check connectivity before syncing
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        talker.debug('Skipping background sync due to no connectivity');
        return;
      }

      // Run sync in background
      _lastSyncAttempt = DateTime.now();
      syncWithFirestore(inBackground: true);
    } catch (e) {
      talker.debug('Error checking connectivity: $e');
    }
  }

  /// Prefetch images for visible cards to improve performance
  Future<void> prefetchVisibleCardImages(List<Card> visibleCards) async {
    try {
      for (final card in visibleCards.take(20)) {
        final imageUrl = card.getBestImageUrl();
        if (imageUrl != null) {
          CardImageUtils.prefetchImage(imageUrl);
        }
      }
    } catch (e, stack) {
      talker.error('Error loading cards', e, stack);
      rethrow;
    }
  }

  /// Sync with Firestore, optionally in background
  Future<void> syncWithFirestore(
      {bool inBackground = false, bool force = false}) async {
    // Prevent multiple syncs
    if (_isSyncing) {
      talker.debug('Sync already in progress, skipping');
      return;
    }

    _isSyncing = true;

    try {
      // Check connectivity
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        talker.info('Skipping sync due to no connectivity');
        _isSyncing = false;
        return;
      }

      final cache = await ref.watch(cardCacheNotifierProvider.future);
      final firestoreService = ref.read(firestoreServiceProvider);

      // Get local and remote versions
      int localVersion = 0;
      try {
        if (cache is CacheService) {
          localVersion = await cache.getDataVersion() ?? 0;
        }
      } catch (e) {
        talker.debug('Error getting data version: $e');
      }

      final metadata = await firestoreService.getMetadata();
      final remoteVersion = metadata['version'] as int? ?? 1;

      // Skip if versions match and not forced
      if (localVersion == remoteVersion && !force) {
        talker.info(
            'Local version matches remote ($localVersion), skipping sync');
        _isSyncing = false;
        return;
      }

      talker
          .info('Syncing cards (local: $localVersion, remote: $remoteVersion)');

      // If we have a local version, only fetch updated cards
      if (localVersion > 0 && !force) {
        final updatedCards =
            await firestoreService.getCardsUpdatedSince(localVersion);

        if (updatedCards.isEmpty) {
          talker.info('No updated cards found, updating version only');
          try {
            if (cache is CacheService) {
              await cache.setDataVersion(remoteVersion);
              await cache.setLastSyncTime(DateTime.now());
            }
          } catch (e) {
            talker.debug('Error setting data version: $e');
          }
          _isSyncing = false;
          return;
        }

        talker.info('Found ${updatedCards.length} updated cards');

        // Get existing cards and merge with updates
        final existingCards = await cache.getCachedCards();
        final cardMap = {for (var card in existingCards) card.productId: card};

        // Update with new cards
        for (var card in updatedCards) {
          cardMap[card.productId] = card;
        }

        // Save merged cards
        final mergedCards = cardMap.values.toList();
        await cache.cacheCards(mergedCards);
        try {
          if (cache is CacheService) {
            await cache.setDataVersion(remoteVersion);
            await cache.setLastSyncTime(DateTime.now());
          }
        } catch (e) {
          talker.debug('Error setting data version: $e');
        }

        // Update state if not in background
        if (!inBackground) {
          state = AsyncData(mergedCards);
        }
      } else {
        // Full sync
        talker.info('Performing full sync');
        final cards = await _fetchCardsFromFirestore();

        // Update state if not in background
        if (!inBackground && cards.isNotEmpty) {
          state = AsyncData(cards);
        }
      }

      talker.info('Sync completed successfully');
    } catch (e, stack) {
      talker.error('Error syncing with Firestore', e, stack);
    } finally {
      _isSyncing = false;
      _lastSyncAttempt = DateTime.now();
    }
  }

  /// Search cards using local data instead of Firestore queries
  Future<List<Card>> searchCards(String searchTerm) async {
    try {
      final cache = await ref.watch(cardCacheNotifierProvider.future);
      final normalizedQuery = searchTerm.toLowerCase().trim();

      if (normalizedQuery.isEmpty) {
        return [];
      }

      // Check cache first
      final cachedResults = await cache.getCachedSearchResults(normalizedQuery);
      if (cachedResults != null) {
        talker.debug('Using cached search results for query: $normalizedQuery');
        return cachedResults;
      }

      talker.debug('Search query: "$normalizedQuery"');

      // Generate search terms - always include the full query
      final searchTerms = <String>{normalizedQuery};

      // IMPORTANT: Always add progressive substrings for any query
      // This ensures queries like "Clou" will match "Cloud"
      for (int i = 1; i <= normalizedQuery.length; i++) {
        searchTerms.add(normalizedQuery.substring(0, i));
      }

      // Handle number formats with more comprehensive variations
      if (normalizedQuery.contains('-') ||
          RegExp(r'[0-9]').hasMatch(normalizedQuery)) {
        // Add original number format
        searchTerms.add(normalizedQuery);

        // If query contains hyphen (e.g., "1-001H" or "20-040L")
        if (normalizedQuery.contains('-')) {
          final parts = normalizedQuery.split('-');
          if (parts.length == 2) {
            final prefix = parts[0];
            final suffix = parts[1];

            // Add set number variations (e.g., "1", "20")
            if (prefix.isNotEmpty) {
              searchTerms.add(prefix);
              searchTerms.add('$prefix-');
            }

            // Add progressive card number variations
            if (prefix.isNotEmpty && suffix.isNotEmpty) {
              // Add all progressive substrings of the suffix
              for (int i = 1; i <= suffix.length; i++) {
                searchTerms.add('$prefix-${suffix.substring(0, i)}');
              }

              // For suffixes with letters (e.g., "001H"), also add variations without the letter
              final numericPart = RegExp(r'(\d+)').firstMatch(suffix)?.group(1);
              if (numericPart != null && numericPart != suffix) {
                searchTerms.add('$prefix-$numericPart');

                // Add progressive substrings of the numeric part
                for (int i = 1; i <= numericPart.length; i++) {
                  searchTerms.add('$prefix-${numericPart.substring(0, i)}');
                }
              }

              // Add just the numeric part without the prefix
              if (numericPart != null) {
                searchTerms.add(numericPart);
              }
            }
          }
        }
        // If it's just a number (potential set number), add variations
        else if (RegExp(r'^\d+$').hasMatch(normalizedQuery)) {
          // For single digit searches (like "1"), add special handling
          if (normalizedQuery.length == 1) {
            // Add the set prefix format (e.g., "1-")
            searchTerms.add('$normalizedQuery-');

            // Add common card number patterns for this set
            // For example, for "1", add "1-001", "1-002", etc.
            for (int i = 1; i <= 999; i += 100) {
              final formattedNum = i.toString().padLeft(3, '0');
              searchTerms.add('$normalizedQuery-$formattedNum');
            }

            // Add variations with common rarities
            for (final rarity in ['C', 'H', 'L', 'R', 'S']) {
              searchTerms.add('$normalizedQuery-001$rarity');
            }
          }

          searchTerms.add('$normalizedQuery-');

          // Also add variations for partial number matches
          for (int i = 1; i <= normalizedQuery.length; i++) {
            searchTerms.add(normalizedQuery.substring(0, i));
          }

          // Add variations with common set prefixes
          // This helps with searches like "1" matching "1-001H"
          for (final setPrefix in [
            '1-',
            '2-',
            '3-',
            '4-',
            '5-',
            '6-',
            '7-',
            '8-',
            '9-',
            '10-',
            '11-',
            '12-',
            '13-',
            '14-',
            '15-',
            '16-',
            '17-',
            '18-',
            '19-',
            '20-',
            '21-',
            '22-'
          ]) {
            if (normalizedQuery.length <= 3) {
              searchTerms.add('$setPrefix$normalizedQuery');
            }
          }
        }
      }

      talker.debug('Generated search terms: ${searchTerms.join(', ')}');

      // IMPORTANT: Instead of querying Firestore, search locally
      // Get all cards from the repository
      final allCards = await future;

      // Search locally by checking if any card's searchTerms match our query terms
      final results = allCards.where((card) {
        // Check if any of the card's searchTerms match any of our query's searchTerms
        return card.searchTerms.any((term) =>
            searchTerms.contains(term) ||
            term.startsWith(normalizedQuery) ||
            searchTerms.any((searchTerm) => term.startsWith(searchTerm)));
      }).toList();

      talker.debug(
          'Found ${results.length} cards locally for query "$normalizedQuery"');

      // Determine if this is a card number search
      final isCardNumberSearch = normalizedQuery.contains('-') ||
          RegExp(r'^\d+$').hasMatch(normalizedQuery);

      // Helper function to calculate relevance score
      int getRelevance(Card card) {
        final name = card.name.toLowerCase();
        final number = card.number?.toLowerCase() ?? '';
        final cardNumbers =
            card.cardNumbers.map((n) => n.toLowerCase()).toList();

        // Exact matches get highest priority
        if (name == normalizedQuery ||
            number == normalizedQuery ||
            cardNumbers.contains(normalizedQuery)) {
          return 10;
        }

        // For card number searches, prioritize card number matches
        if (isCardNumberSearch) {
          // For single digit searches like "1", prioritize cards by number within that set
          if (normalizedQuery.length == 1 &&
              RegExp(r'^\d+$').hasMatch(normalizedQuery)) {
            // Exact set match (e.g., "1-001H" for query "1")
            if (number.startsWith('$normalizedQuery-') ||
                cardNumbers.any((n) => n.startsWith('$normalizedQuery-'))) {
              // Extract the numeric part to sort by card number within the set
              final numericPart =
                  RegExp(r'-(\d+)').firstMatch(number)?.group(1);
              if (numericPart != null) {
                // Lower numbers get higher priority (001 > 002 > etc.)
                final numValue = int.tryParse(numericPart) ?? 999;
                // Return a score between 6-9 based on card number
                // Cards 001-099 get score 9, 100-199 get score 8, etc.
                return 9 - (numValue ~/ 100).clamp(0, 3);
              }
              return 6; // Default priority for set matches
            }
          }

          // Card number exact match
          if (number == normalizedQuery ||
              cardNumbers.contains(normalizedQuery)) {
            return 9;
          }

          // Card number starts with query
          if (number.startsWith(normalizedQuery) ||
              cardNumbers.any((n) => n.startsWith(normalizedQuery))) {
            return 8;
          }

          // Card number contains query
          if (number.contains(normalizedQuery) ||
              cardNumbers.any((n) => n.contains(normalizedQuery))) {
            return 7;
          }

          // Set number matches (e.g., searching for "1" matches "1-001H")
          if (number.startsWith('$normalizedQuery-') ||
              cardNumbers.any((n) => n.startsWith('$normalizedQuery-'))) {
            return 6;
          }
        }
        // For name searches, prioritize name matches
        else {
          // Name starts with query
          if (name.startsWith(normalizedQuery)) {
            return 9;
          }

          // Word in name starts with query
          if (name.split(' ').any((word) => word.startsWith(normalizedQuery))) {
            return 8;
          }

          // Name contains query
          if (name.contains(normalizedQuery)) {
            return 7;
          }
        }

        // Lower priority matches
        // Card number starts with query (for name searches)
        if (!isCardNumberSearch &&
            (number.startsWith(normalizedQuery) ||
                cardNumbers.any((n) => n.startsWith(normalizedQuery)))) {
          return 5;
        }

        // Name starts with query (for card number searches)
        if (isCardNumberSearch && name.startsWith(normalizedQuery)) {
          return 4;
        }

        // Any other match in searchTerms
        if (card.searchTerms.any((term) =>
            term.startsWith(normalizedQuery) ||
            searchTerms.any((searchTerm) => term.startsWith(searchTerm)))) {
          return 3;
        }

        // No relevant match
        return 0;
      }

      // Enhanced relevance sorting
      results.sort((a, b) {
        final relevanceA = getRelevance(a);
        final relevanceB = getRelevance(b);

        // If both have same relevance, sort based on query type
        if (relevanceA == relevanceB) {
          if (isCardNumberSearch) {
            // For card number searches, sort by card number first
            return a.compareByNumber(b);
          } else {
            // For name searches, sort alphabetically by name first, then by card number
            return a.compareByName(b);
          }
        }
        // Otherwise sort by relevance
        return relevanceB.compareTo(relevanceA);
      });

      // Filter cards with 0 relevance and improve matching logic
      final filteredResults = results.where((card) {
        final name = card.name.toLowerCase();
        final number = card.number?.toLowerCase() ?? '';
        final cardNumbers =
            card.cardNumbers.map((n) => n.toLowerCase()).toList();

        // For card number searches, be more lenient with matching
        if (isCardNumberSearch) {
          // For single digit searches like "1", match all cards from that set
          if (normalizedQuery.length == 1 &&
              RegExp(r'^\d+$').hasMatch(normalizedQuery)) {
            // Match any card number that starts with the digit followed by a hyphen
            // This will match all cards from set 1 (e.g., "1-001H", "1-002C", etc.)
            return number.startsWith('$normalizedQuery-') ||
                cardNumbers.any((n) => n.startsWith('$normalizedQuery-'));
          }

          // Match card numbers that start with the query
          if (number.startsWith(normalizedQuery) ||
              cardNumbers.any((n) => n.startsWith(normalizedQuery))) {
            return true;
          }

          // Match set numbers (e.g., "1" matches "1-001H")
          if (normalizedQuery.length <= 2 && !normalizedQuery.contains('-')) {
            if (number.startsWith('$normalizedQuery-') ||
                cardNumbers.any((n) => n.startsWith('$normalizedQuery-'))) {
              return true;
            }
          }

          // For queries with hyphens, be more specific
          if (normalizedQuery.contains('-')) {
            final parts = normalizedQuery.split('-');
            if (parts.length == 2) {
              final prefix = parts[0];
              final suffix = parts[1];

              // Match card numbers that start with the same prefix and suffix
              return number.startsWith('$prefix-$suffix') ||
                  cardNumbers.any((n) => n.startsWith('$prefix-$suffix'));
            }
          }

          // For numeric queries without hyphens, also check if they appear in the number
          if (RegExp(r'^\d+$').hasMatch(normalizedQuery)) {
            return number.contains(normalizedQuery) ||
                cardNumbers.any((n) => n.contains(normalizedQuery));
          }
        }
        // For name searches
        else {
          if (normalizedQuery.length <= 3) {
            // For short queries, must exactly match or start with query
            return name.startsWith(normalizedQuery) ||
                name.split(' ').any((word) => word.startsWith(normalizedQuery));
          }

          // For longer queries, must at least partially match
          return name.contains(normalizedQuery) ||
              name.split(' ').any((word) => word.startsWith(normalizedQuery));
        }

        return false;
      }).toList();

      // Cache the results
      await cache.cacheSearchResults(normalizedQuery, filteredResults);

      // Also cache progressive substrings for better partial matching
      if (filteredResults.isNotEmpty && normalizedQuery.length > 1) {
        for (int i = 1; i < normalizedQuery.length; i++) {
          final substring = normalizedQuery.substring(0, i);

          // For card number searches, be more comprehensive with substring caching
          if (isCardNumberSearch) {
            final substringResults = filteredResults.where((card) {
              final number = card.number?.toLowerCase() ?? '';
              final cardNumbers =
                  card.cardNumbers.map((n) => n.toLowerCase()).toList();

              // For single digit searches like "1", match all cards from that set
              if (substring.length == 1 &&
                  RegExp(r'^\d+$').hasMatch(substring)) {
                // Match any card number that starts with the digit followed by a hyphen
                return number.startsWith('$substring-') ||
                    cardNumbers.any((n) => n.startsWith('$substring-'));
              }

              // For card numbers, check various matching patterns
              if (number.startsWith(substring) ||
                  cardNumbers.any((n) => n.startsWith(substring))) {
                return true;
              }

              // Handle set number prefixes (e.g., "1" should match "1-001H")
              if (!substring.contains('-') &&
                  (number.startsWith('$substring-') ||
                      cardNumbers.any((n) => n.startsWith('$substring-')))) {
                return true;
              }

              // For numeric substrings, also check if they appear in the number
              if (RegExp(r'^\d+$').hasMatch(substring)) {
                return number.contains(substring) ||
                    cardNumbers.any((n) => n.contains(substring));
              }

              return false;
            }).toList();

            if (substringResults.isNotEmpty) {
              await cache.cacheSearchResults(substring, substringResults);
            }
          }
          // For name searches, focus on name matching
          else {
            final substringResults = filteredResults.where((card) {
              final name = card.name.toLowerCase();
              return name.startsWith(substring) ||
                  name.split(' ').any((word) => word.startsWith(substring));
            }).toList();

            if (substringResults.isNotEmpty) {
              await cache.cacheSearchResults(substring, substringResults);
            }
          }
        }
      }

      return filteredResults;
    } catch (e, stack) {
      talker.error('Error searching cards', e, stack);
      rethrow;
    }
  }

  Future<List<Card>> getFilteredCards(CardFilters filters) async {
    try {
      // Ensure cards are loaded
      if (state.value?.isEmpty ?? true) {
        ref.invalidateSelf();
      }

      final cards = await future;
      return applyLocalFilters(cards, filters);
    } catch (e, stack) {
      talker.error('Error applying filters', e, stack);
      rethrow;
    }
  }

  Future<List<Card>> getCards({
    CardFilters? filters,
    bool forceRefresh = false,
  }) async {
    try {
      // Force refresh if requested
      if (forceRefresh) {
        ref.invalidateSelf();
        // Only clear memory cache on force refresh
        final cache = await ref.watch(cardCacheNotifierProvider.future);
        await cache.clearMemoryCache();
      }

      final cards = await future;

      // Apply default sorting if no filters provided
      filters = filters ??
          const CardFilters(sortField: 'number', sortDescending: false);

      return applyLocalFilters(cards, filters);
    } catch (e, stack) {
      talker.error('Error fetching cards', e, stack);
      rethrow;
    }
  }

  /// Initialize the repository
  Future<void> initialize() async {
    // This method is called from the initialization provider
    // We'll use it to ensure the repository is properly initialized
    try {
      // Clear search cache to ensure fresh results
      final cache = await ref.read(cardCacheNotifierProvider.future);
      try {
        await cache.clearSearchCache();
        talker.info('Search cache cleared');
      } catch (e) {
        talker.debug('Error clearing search cache: $e');
      }

      // Ensure cards are loaded
      await future;

      // Sync with Firestore if needed
      _scheduleBackgroundSync();

      talker.info('Card repository initialized');
    } catch (e, stack) {
      talker.error('Error initializing card repository', e, stack);
    }
  }

  /// Apply filters to a list of cards locally
  List<Card> applyLocalFilters(List<Card> cards, CardFilters filters) {
    // Create a list of indices that match the filters
    final indices = <int>[];
    for (var i = 0; i < cards.length; i++) {
      final card = cards[i];

      // For number, cost, and power sorts, always hide non-cards
      if (filters.sortField == 'number' ||
          filters.sortField == 'cost' ||
          filters.sortField == 'power') {
        if (card.isNonCard) continue;
      } else if (!filters.showSealedProducts && card.isNonCard) {
        // For other sorts, respect showSealedProducts flag
        continue;
      }

      // Apply element filter
      if (filters.elements.isNotEmpty) {
        if (!card.elements.any((e) => filters.elements.contains(e))) {
          continue;
        }
      }

      // Apply type filter
      if (filters.types.isNotEmpty) {
        if (!filters.types.contains(card.cardType)) {
          continue;
        }
      }

      // Apply set filter
      if (filters.set.isNotEmpty) {
        if (!card.set.any((s) => filters.set.contains(s))) {
          continue;
        }
      }

      // Apply rarity filter
      if (filters.rarities.isNotEmpty) {
        if (card.rarity == null || !filters.rarities.contains(card.rarity)) {
          continue;
        }
      }

      // Apply cost filter
      if (filters.minCost != null &&
          (card.cost == null || card.cost! < filters.minCost!)) {
        continue;
      }
      if (filters.maxCost != null &&
          (card.cost == null || card.cost! > filters.maxCost!)) {
        continue;
      }

      // Apply power filter
      if (filters.minPower != null &&
          (card.power == null || card.power! < filters.minPower!)) {
        continue;
      }
      if (filters.maxPower != null &&
          (card.power == null || card.power! > filters.maxPower!)) {
        continue;
      }

      // Apply category filter
      if (filters.categories.isNotEmpty) {
        if (!card.categories.any((c) => filters.categories.contains(c))) {
          continue;
        }
      }

      indices.add(i);
    }

    // Sort indices if needed
    if (filters.sortField != null) {
      indices.sort((a, b) {
        final cardA = cards[a];
        final cardB = cards[b];

        // Check if either card is a crystal card
        final aIsCrystal = cardA.number?.startsWith('C-') ?? false;
        final bIsCrystal = cardB.number?.startsWith('C-') ?? false;

        // If one is crystal and other isn't, crystal comes after
        if (aIsCrystal != bIsCrystal) {
          return aIsCrystal ? 1 : -1;
        }

        // If both are crystal or both are not, use normal sorting
        final comparison = switch (filters.sortField) {
          'number' => cardA.compareByNumber(cardB),
          'name' => cardA.compareByName(cardB),
          'cost' => cardA.compareByCost(cardB) != 0
              ? cardA.compareByCost(cardB)
              : cardA.compareByNumber(cardB),
          'power' => cardA.compareByPower(cardB) != 0
              ? cardA.compareByPower(cardB)
              : cardA.compareByNumber(cardB),
          _ => 0,
        };
        return filters.sortDescending ? -comparison : comparison;
      });
    }

    // Create and return filtered list using sorted indices
    return indices.map((i) => cards[i]).toList();
  }
}
