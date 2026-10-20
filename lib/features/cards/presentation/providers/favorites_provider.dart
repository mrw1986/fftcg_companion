import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider that stores and manages the user's favorite cards
final favoritesProvider =
    NotifierProvider<FavoritesNotifier, List<String>>(
  () => FavoritesNotifier(),
);

/// Notifier class that handles favorite card operations
class FavoritesNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    return [];
  }

  /// Toggle a card's favorite status
  void toggleFavorite(String cardId) {
    if (state.contains(cardId)) {
      state = state.where((id) => id != cardId).toList();
    } else {
      state = [...state, cardId];
    }
  }

  /// Check if a card is marked as favorite
  bool isFavorite(String cardId) {
    return state.contains(cardId);
  }

  /// Add a card to favorites
  void addFavorite(String cardId) {
    if (!state.contains(cardId)) {
      state = [...state, cardId];
    }
  }

  /// Remove a card from favorites
  void removeFavorite(String cardId) {
    if (state.contains(cardId)) {
      state = state.where((id) => id != cardId).toList();
    }
  }
}

/// Provider to check if a specific card is in favorites
final isFavoriteProvider = Provider.family<bool, String>(
  (ref, cardId) {
    final favorites = ref.watch(favoritesProvider);
    return favorites.contains(cardId);
  },
);
