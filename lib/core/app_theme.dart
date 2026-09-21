import 'package:flutter/material.dart';

class AppColours {
  const AppColours._();

  static const green900 = Color(0xFF003E2F);
  static const green800 = Color(0xFF005A3F);
  static const green700 = Color(0xFF007A4D);
  static const green600 = Color(0xFF009B58);
  static const green500 = Color(0xFF00B768);
  static const mint = Color(0xFFE8F7EE);
  static const ink = Color(0xFF15211C);
  static const muted = Color(0xFF66736D);
  static const surface = Color(0xFFF6F8F7);
  static const warning = Color(0xFFF2A93B);
  static const danger = Color(0xFFD64545);
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColours.green700,
    brightness: Brightness.light,
    primary: AppColours.green700,
    secondary: AppColours.green500,
    surface: Colors.white,
    error: AppColours.danger,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColours.surface,
    fontFamily: 'sans-serif',
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: AppColours.ink,
        fontSize: 30,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
      ),
      headlineMedium: TextStyle(
        color: AppColours.ink,
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      titleLarge: TextStyle(
        color: AppColours.ink,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
      titleMedium: TextStyle(
        color: AppColours.ink,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: TextStyle(color: AppColours.ink, height: 1.45),
      bodyMedium: TextStyle(color: AppColours.muted, height: 1.4),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColours.surface,
      foregroundColor: AppColours.ink,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: const TextStyle(color: AppColours.muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE5EAE7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColours.green600, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColours.green700,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontFamily: 'sans-serif', fontWeight: FontWeight.w700),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppColours.mint,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    ),
  );
}

