import 'package:flutter/material.dart';

class AppTheme {
  // --- Renk Paleti ---
  
  // Koyu mod arka planları
  static const Color backgroundDark = Color(0xFF14141E); 
  static const Color cardColor = Color(0xFF1B1E2B);
  
  // Açık mod arka planları
  static const Color backgroundLight = Color(0xFFF2F4FA);
  static const Color cardColorLight = Color(0xFFFFFFFF);
  
  // Metin Renkleri (koyu mod)
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFA1A1AB);
  
  // Metin Renkleri (açık mod)
  static const Color textPrimaryLight = Color(0xFF1A1A2E);
  static const Color textSecondaryLight = Color(0xFF6B7280);

  // Vurgu (Accent) Renkleri (her iki modda da aynı)
  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color expenseRed = Color(0xFFFF4D4D);
  static const Color incomeGreen = Color(0xFF34D399);
  static const Color starYellow = Color(0xFFFBBF24);
  
  // --- Koyu Tema ---
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundDark,
      primaryColor: primaryPurple,
      colorScheme: const ColorScheme.dark(
        primary: primaryPurple,
        secondary: primaryPurple,
        surface: cardColor,
        background: backgroundDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: backgroundDark,
        selectedItemColor: primaryPurple,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: expenseRed,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      fontFamily: 'Inter',
    );
  }

  // --- Açık Tema (Premium Soft Light) ---
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: backgroundLight,
      primaryColor: primaryPurple,
      colorScheme: const ColorScheme.light(
        primary: primaryPurple,
        secondary: primaryPurple,
        surface: cardColorLight,
        background: backgroundLight,
        onBackground: textPrimaryLight,
        onSurface: textPrimaryLight,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundLight,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: textPrimaryLight),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimaryLight,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cardColorLight,
        selectedItemColor: primaryPurple,
        unselectedItemColor: textSecondaryLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      cardTheme: CardThemeData(
        color: cardColorLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        elevation: 1,
        shadowColor: Colors.black12,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      dialogBackgroundColor: cardColorLight,
      fontFamily: 'Inter',
    );
  }
}
