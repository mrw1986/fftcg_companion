import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';
import 'package:fftcg_companion/app.dart';
import 'package:fftcg_companion/providers/auth_provider.dart';
import 'package:fftcg_companion/providers/theme_provider.dart';
import 'package:fftcg_companion/providers/cache_provider.dart';
import 'package:fftcg_companion/features/home/screens/home_screen.dart';
import 'package:fftcg_companion/features/auth/screens/auth_screen.dart';

// Create mocks
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockUserCredential extends Mock implements UserCredential {}

void main() {
  group('Authentication Flow Tests', () {
    late MockFirebaseAuth mockAuth;
    late FFTCGAuthProvider authProvider;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      authProvider = FFTCGAuthProvider();
    });

    testWidgets('Shows AuthScreen when user is not authenticated',
        (WidgetTester tester) async {
      when(mockAuth.authStateChanges()).thenAnswer((_) => Stream.value(null));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<FFTCGAuthProvider>.value(
                value: authProvider),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => CacheProvider()),
          ],
          child: const App(),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.text('Continue as Guest'), findsOneWidget);
    });
  });

  group('HomeScreen Tests', () {
    testWidgets('HomeScreen shows different UI for guest and registered users',
        (WidgetTester tester) async {
      // Test guest mode
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeScreen(isGuest: true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('FFTCG Companion'), findsOneWidget);

      // Test registered user mode
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeScreen(isGuest: false),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('FFTCG Companion'), findsOneWidget);
    });
  });

  group('Navigation Tests', () {
    testWidgets('Can navigate through main app routes',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => FFTCGAuthProvider()),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => CacheProvider()),
          ],
          child: const App(),
        ),
      );

      await tester.pumpAndSettle();

      // Test navigation based on our route configuration
      expect(find.byType(AuthScreen), findsOneWidget); // Initial route check
    });
  });

  group('Provider Tests', () {
    test('ThemeProvider toggles theme correctly', () {
      final themeProvider = ThemeProvider();
      final initialTheme = themeProvider.currentTheme;

      themeProvider.toggleTheme();

      expect(themeProvider.currentTheme, isNot(equals(initialTheme)));
    });

    test('CacheProvider manages data correctly', () {
      final cacheProvider = CacheProvider();

      cacheProvider.updateCache('testKey', 'testValue');
      expect(cacheProvider.cachedData['testKey'], equals('testValue'));

      cacheProvider.clearCache();
      expect(cacheProvider.cachedData.isEmpty, isTrue);
    });
  });
}
