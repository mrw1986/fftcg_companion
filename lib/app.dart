import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'config/routes.dart';
import 'providers/auth_provider.dart' as app_auth;
import 'providers/theme_provider.dart';
import 'features/home/screens/home_screen.dart';
import 'widgets/common/loading_screen.dart';
import 'features/auth/screens/auth_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<app_auth.FFTCGAuthProvider, ThemeProvider>(
      // Update to use FFTCGAuthProvider
      builder: (context, authProvider, themeProvider, _) {
        return MaterialApp(
          title: 'FFTCG Companion',
          theme: themeProvider.currentTheme,
          routes: AppRoutes.routes,
          home: StreamBuilder<User?>(
            stream: authProvider
                .authStateChanges, // Remove null check since Consumer guarantees non-null
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingScreen();
              }

              if (snapshot.hasData) {
                final isGuest = snapshot.data!.isAnonymous;
                return HomeScreen(isGuest: isGuest);
              }

              return const AuthScreen();
            },
          ),
        );
      },
    );
  }
}
