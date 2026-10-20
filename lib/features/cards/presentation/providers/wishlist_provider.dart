import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider that stores and manages the user's wishlist cards
final wishlistProvider = NotifierProvider<WishlistNotifier, List<String>>(
  () => WishlistNotifier(),
);

/// Notifier class that handles wishlist card operations
class WishlistNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    return [];
  }

  /// Toggle a card's wishlist status
  void toggleWishlist(String cardId) {
    if (state.contains(cardId)) {
      state = state.where((id) => id != cardId).toList();
    } else {
      state = [...state, cardId];
    }
  }

  /// Check if a card is in the wishlist
  bool isInWishlist(String cardId) {
    return state.contains(cardId);
  }

  /// Add a card to wishlist
  void addToWishlist(String cardId) {
    if (!state.contains(cardId)) {
      state = [...state, cardId];
    }
  }

  /// Remove a card from wishlist
  void removeFromWishlist(String cardId) {
    if (state.contains(cardId)) {
      state = state.where((id) => id != cardId).toList();
    }
  }
}

/// Provider to check if a specific card is in wishlist
final isInWishlistProvider = Provider.family<bool, String>(
  (ref, cardId) {
    final wishlist = ref.watch(wishlistProvider);
    return wishlist.contains(cardId);
  },
);
