import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B1B2B),
          brightness: Brightness.light,
        ).copyWith(
          secondary: const Color(0xFF10B981),
          secondaryContainer: const Color(0xFFD1FAE5),
          onSecondary: const Color(0xFFFFFFFF),
          onSecondaryContainer: const Color(0xFF064E3B),
        ),
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0B1B2B),
      foregroundColor: Color(0xFFFFFFFF),
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: const Color(0xFFFFFFFF),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      side: BorderSide.none,
      selectedColor: const Color(0xFF10B981),
      disabledColor: const Color(0xFFE2E8F0),
      backgroundColor: const Color(0xFFE0E7FF),
      labelStyle: const TextStyle(fontWeight: FontWeight.w700),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B1B2B),
          brightness: Brightness.dark,
        ).copyWith(
          secondary: const Color(0xFF10B981),
          secondaryContainer: const Color(0xFF064E3B),
          onSecondary: const Color(0xFFFFFFFF),
          onSecondaryContainer: const Color(0xFFD1FAE5),
        ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0B1B2B),
      foregroundColor: Color(0xFFFFFFFF),
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: const Color(0xFFFFFFFF),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      side: BorderSide.none,
      selectedColor: const Color(0xFF10B981),
      disabledColor: const Color(0xFF475569),
      backgroundColor: const Color(0xFF1E293B),
      labelStyle: const TextStyle(fontWeight: FontWeight.w700),
    ),
  );
}
