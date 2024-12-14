import 'package:flutter/material.dart';
import '../config/theme.dart';

class ThemeProvider with ChangeNotifier {
  ThemeData _currentTheme = AppTheme.lightTheme;

  ThemeData get currentTheme => _currentTheme;

  void toggleTheme() {
    _currentTheme = _currentTheme == AppTheme.lightTheme
        ? AppTheme.darkTheme
        : AppTheme.lightTheme;
    notifyListeners();
  }
}
