// lib/app.dart
import 'package:flutter/material.dart';
import 'package:fftcg_companion/config/theme.dart';
import 'package:fftcg_companion/config/routes.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FFTCG Companion',
      theme: appTheme,
      darkTheme: appDarkTheme,
      initialRoute: '/auth',
      routes: appRoutes,
    );
  }
}
