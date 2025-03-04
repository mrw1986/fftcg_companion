import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fftcg_companion/features/profile/presentation/providers/splash_screen_provider.dart';

class CustomSplashScreen extends ConsumerStatefulWidget {
  final Widget child;

  const CustomSplashScreen({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<CustomSplashScreen> createState() => _CustomSplashScreenState();
}

class _CustomSplashScreenState extends ConsumerState<CustomSplashScreen> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _initSplashScreen();
  }

  Future<void> _initSplashScreen() async {
    final splashPrefs = ref.read(splashScreenPreferencesProvider);

    if (!splashPrefs.enabled) {
      setState(() {
        _showSplash = false;
      });
      return;
    }

    await Future.delayed(Duration(seconds: splashPrefs.durationInSeconds));

    if (mounted) {
      setState(() {
        _showSplash = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_showSplash) {
      return widget.child;
    }

    // Get the system brightness directly
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final isDarkMode = platformBrightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        body: Center(
          child: Image.asset(
            'assets/images/logo_transparent.png',
            width: 200,
            height: 200,
            color: isDarkMode
                ? Colors.white
                : Colors.black, // White in dark mode, black in light mode
          ),
        ),
      ),
    );
  }
}
