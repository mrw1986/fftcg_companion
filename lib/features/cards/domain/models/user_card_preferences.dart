import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a user's preferences for cards (favorites, wishlist)
class UserCardPreferences {
  final String userId;
  final List<String> favoriteCardIds;
  final List<String> wishlistCardIds;
  final DateTime updatedAt;

  UserCardPreferences({
    required this.userId,
    this.favoriteCardIds = const [],
    this.wishlistCardIds = const [],
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  /// Create an empty preferences instance for a user
  factory UserCardPreferences.empty(String userId) {
    return UserCardPreferences(
      userId: userId,
      favoriteCardIds: [],
      wishlistCardIds: [],
    );
  }

  /// Create from Firestore document
  factory UserCardPreferences.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      return UserCardPreferences.empty(snapshot.id);
    }

    return UserCardPreferences(
      userId: snapshot.id,
      favoriteCardIds: List<String>.from(data['favoriteCardIds'] ?? []),
      wishlistCardIds: List<String>.from(data['wishlistCardIds'] ?? []),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'favoriteCardIds': favoriteCardIds,
      'wishlistCardIds': wishlistCardIds,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy with modified properties
  UserCardPreferences copyWith({
    String? userId,
    List<String>? favoriteCardIds,
    List<String>? wishlistCardIds,
    DateTime? updatedAt,
  }) {
    return UserCardPreferences(
      userId: userId ?? this.userId,
      favoriteCardIds: favoriteCardIds ?? this.favoriteCardIds,
      wishlistCardIds: wishlistCardIds ?? this.wishlistCardIds,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Add or remove a card from favorites
  UserCardPreferences toggleFavorite(String cardId) {
    final List<String> newFavorites = List.from(favoriteCardIds);
    if (newFavorites.contains(cardId)) {
      newFavorites.remove(cardId);
    } else {
      newFavorites.add(cardId);
    }
    return copyWith(
      favoriteCardIds: newFavorites,
      updatedAt: DateTime.now(),
    );
  }

  /// Add or remove a card from wishlist
  UserCardPreferences toggleWishlist(String cardId) {
    final List<String> newWishlist = List.from(wishlistCardIds);
    if (newWishlist.contains(cardId)) {
      newWishlist.remove(cardId);
    } else {
      newWishlist.add(cardId);
    }
    return copyWith(
      wishlistCardIds: newWishlist,
      updatedAt: DateTime.now(),
    );
  }

  /// Check if a card is in favorites
  bool isFavorite(String cardId) => favoriteCardIds.contains(cardId);

  /// Check if a card is in wishlist
  bool isInWishlist(String cardId) => wishlistCardIds.contains(cardId);
}
