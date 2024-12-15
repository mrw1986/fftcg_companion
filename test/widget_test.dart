import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';
import 'package:fftcg_companion/app.dart';
import 'package:fftcg_companion/providers/auth_provider.dart';
import 'package:fftcg_companion/providers/theme_provider.dart';
import 'package:fftcg_companion/providers/cache_provider.dart';
import 'package:fftcg_companion/features/home/screens/home_screen.dart';
import 'package:fftcg_companion/features/auth/screens/auth_screen.dart';
import 'package:fftcg_companion/features/deck_builder/screens/deck_builder_screen.dart';
import 'package:fftcg_companion/config/routes.dart';

// Mock classes
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockUserCredential extends Mock implements UserCredential {}

// Setup Firebase for testing
Future<void> setupFirebaseForTesting() async {
  await Firebase.initializeApp();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setupFirebaseForTesting();
  });

  group('App Initialization Tests', () {
    testWidgets('App shows loading screen initially',
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

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('Authentication Flow Tests', () {
    late MockFirebaseAuth mockAuth;
    late FFTCGAuthProvider authProvider;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      authProvider = FFTCGAuthProvider();
    });

    testWidgets('Guest login flow', (WidgetTester tester) async {
      final mockUserCredential = MockUserCredential();
      final mockUser = MockUser();

      when(mockAuth.signInAnonymously())
          .thenAnswer((_) async => mockUserCredential);
      when(mockUser.isAnonymous).thenReturn(true);

      await tester.pumpWidget(
        MaterialApp(
          home: AuthScreen(),
        ),
      );

      await tester.tap(find.text('Continue as Guest'));
      await tester.pumpAndSettle();

      verify(mockAuth.signInAnonymously()).called(1);
    });
  });

  group('Navigation Tests', () {
    testWidgets('Can navigate to deck builder', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: AppRoutes.routes,
          home: const HomeScreen(isGuest: false),
        ),
      );

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.byType(DeckBuilderScreen), findsOneWidget);
    });
  });

  group('Theme Tests', () {
    testWidgets('Theme toggle updates UI', (WidgetTester tester) async {
      final themeProvider = ThemeProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeProvider>.value(
          value: themeProvider,
          child: MaterialApp(
            home: HomeScreen(isGuest: false),
          ),
        ),
      );

      final initialBrightness = tester
          .widget<MaterialApp>(find.byType(MaterialApp))
          .theme
          ?.brightness;

      themeProvider.toggleTheme();
      await tester.pumpAndSettle();

      final newBrightness = tester
          .widget<MaterialApp>(find.byType(MaterialApp))
          .theme
          ?.brightness;

      expect(newBrightness, isNot(equals(initialBrightness)));
    });
  });

  group('Cache Tests', () {
    test('Cache operations work correctly', () {
      final cacheProvider = CacheProvider();

      // Test cache update
      cacheProvider.updateCache('testKey', 'testValue');
      expect(cacheProvider.cachedData['testKey'], equals('testValue'));

      // Test cache clear
      cacheProvider.clearCache();
      expect(cacheProvider.cachedData.isEmpty, isTrue);
    });
  });

  group('Performance Tests', () {
    testWidgets('Screen transitions complete within threshold',
        (WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(isGuest: false),
        ),
      );

      await tester.pumpAndSettle();
      stopwatch.stop();

      expect(
          stopwatch.elapsedMilliseconds, lessThan(1000)); // 1-second threshold
    });
  });
}
