import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fftcg_companion/features/cards/presentation/widgets/card_content.dart';

/// Provider to access the CardContentState from anywhere in the app
final cardContentKeyProvider = Provider<GlobalKey<CardContentState>>((ref) {
  return GlobalKey<CardContentState>();
});

/// Extension method to scroll to top
extension CardContentExtension on WidgetRef {
  void scrollCardsToTop() {
    final key = read(cardContentKeyProvider);
    if (key.currentState != null) {
      key.currentState!.scrollToTop();
    }
  }
}
