import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fftcg_companion/app.dart';
import 'package:fftcg_companion/providers/auth_provider.dart';
import 'package:fftcg_companion/providers/theme_provider.dart';
import 'package:fftcg_companion/providers/cache_provider.dart';
import 'package:fftcg_companion/widgets/common/loading_screen.dart';

void main() {
  group('App Widget Tests', () {
    testWidgets('App shows LoadingScreen initially',
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

      expect(find.byType(LoadingScreen), findsOneWidget);
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
