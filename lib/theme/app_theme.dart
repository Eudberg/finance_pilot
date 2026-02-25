import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF0EA5E9),
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFF7FAFF),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
      side: BorderSide.none,
      selectedColor: const Color(0xFFBAE6FD),
      disabledColor: const Color(0xFFE5E7EB),
      backgroundColor: const Color(0xFFE0F2FE),
      labelStyle: const TextStyle(
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF22D3EE),
      brightness: Brightness.dark,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
      side: BorderSide.none,
      selectedColor: const Color(0xFF164E63),
      disabledColor: const Color(0xFF334155),
      backgroundColor: const Color(0xFF1E293B),
      labelStyle: const TextStyle(
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
