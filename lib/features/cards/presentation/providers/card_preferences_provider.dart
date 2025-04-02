import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fftcg_companion/features/cards/data/repositories/card_preferences_repository.dart';
import 'package:fftcg_companion/features/cards/domain/models/user_card_preferences.dart';
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:fftcg_companion/core/providers/auth_provider.dart';

/// AsyncNotifier for user card preferences
class CardPreferencesNotifier extends AsyncNotifier<UserCardPreferences> {
  CardPreferencesRepository get _repository =>
      ref.read(cardPreferencesRepositoryProvider);

  @override
  Future<UserCardPreferences> build() async {
    // Listen to auth changes to update preferences when user changes
    ref.listen(authStateProvider, (previous, next) {
      if (previous != next) {
        ref.invalidateSelf();
      }
    });

    try {
      return await _repository.getUserPreferences();
    } catch (e) {
      talker.error('Error loading user preferences: $e');
      // Return empty preferences on error
      return UserCardPreferences.empty('anonymous');
    }
  }

  /// Toggle a card's favorite status
  Future<void> toggleFavorite(String cardId) async {
    try {
      // Start optimistic update
      final currentState = state.valueOrNull;
      if (currentState == null) return;

      // Optimistically update UI
      state = AsyncData(currentState.toggleFavorite(cardId));

      // Update in Firestore
      await _repository.toggleFavorite(cardId);
    } catch (e) {
      talker.error('Error toggling favorite status: $e');
      // Reload state on error
      ref.invalidateSelf();
    }
  }

  /// Toggle a card's wishlist status
  Future<void> toggleWishlist(String cardId) async {
    try {
      // Start optimistic update
      final currentState = state.valueOrNull;
      if (currentState == null) return;

      // Optimistically update UI
      state = AsyncData(currentState.toggleWishlist(cardId));

      // Update in Firestore
      await _repository.toggleWishlist(cardId);
    } catch (e) {
      talker.error('Error toggling wishlist status: $e');
      // Reload state on error
      ref.invalidateSelf();
    }
  }
}

/// Provider for user card preferences
final cardPreferencesProvider =
    AsyncNotifierProvider<CardPreferencesNotifier, UserCardPreferences>(
  () => CardPreferencesNotifier(),
);

/// Provider to check if a specific card is in favorites
final isFavoriteProvider = Provider.family<bool, String>((ref, cardId) {
  final preferencesAsync = ref.watch(cardPreferencesProvider);
  return preferencesAsync.maybeWhen(
    data: (preferences) => preferences.isFavorite(cardId),
    orElse: () => false,
  );
});

/// Provider to check if a specific card is in wishlist
final isInWishlistProvider = Provider.family<bool, String>((ref, cardId) {
  final preferencesAsync = ref.watch(cardPreferencesProvider);
  return preferencesAsync.maybeWhen(
    data: (preferences) => preferences.isInWishlist(cardId),
    orElse: () => false,
  );
});

/// Provider for a stream of card preferences for the current user
final cardPreferencesStreamProvider =
    StreamProvider<UserCardPreferences>((ref) {
  final repository = ref.watch(cardPreferencesRepositoryProvider);
  return repository.getUserPreferencesStream();
});
