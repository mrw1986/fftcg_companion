import 'package:flutter/material.dart';
import '../features/auth/screens/email_sign_in_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/deck_builder/screens/deck_builder_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String emailSignIn = '/email-signin';
  static const String profile = '/profile';
  static const String deckBuilder = '/deck-builder';

  static Map<String, WidgetBuilder> routes = {
    emailSignIn: (context) => const EmailSignInScreen(),
    profile: (context) => const ProfileScreen(),
    deckBuilder: (context) => const DeckBuilderScreen(),
  };
}
