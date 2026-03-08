import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      // In a real app we'd get the actual system brightness, but for simplicity:
      return false;
    }
    return _themeMode == ThemeMode.dark;
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF00B4D8),
        primary: const Color(0xFF00B4D8),
        secondary: const Color(0xFF90E0EF),
        surface: const Color(0xFFF8F9FA),
      ),
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF0077B6),
        elevation: 0,
        centerTitle: true,
      ),
      useMaterial3: true,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: const Color(0xFF00B4D8),
        primary: const Color(0xFF00B4D8),
        secondary: const Color(0xFF0077B6),
        surface: const Color(0xFF1E1E2C), // Dark surface
      ),
      scaffoldBackgroundColor: const Color(0xFF121212), // Deep dark background
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E2C),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      cardColor: const Color(0xFF1E1E2C),
      useMaterial3: true,
    );
  }
}
