import 'package:flutter/material.dart';

// ──────────────────────────────────────────────
// Brand colours
// ──────────────────────────────────────────────
const Color _primaryLight = Color(0xFF0D47A1);
const Color _primaryDark = Color(0xFF4A90D9); // brighter for dark-mode contrast

class AppTheme {
  AppTheme._();

  // ─────────── LIGHT ───────────
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryLight,
          brightness: Brightness.light,
          primary: _primaryLight,
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: const Color(0xFF1E293B),
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F7FA),
        cardColor: Colors.white,
        dividerColor: const Color(0xFFE2E8F0),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1E293B),
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: _primaryLight,
          unselectedItemColor: Color(0xFF94A3B8),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
          labelStyle: const TextStyle(color: Color(0xFF64748B)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _primaryLight, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
          headlineSmall: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
          titleLarge: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: Color(0xFF1E293B)),
          bodyMedium: TextStyle(color: Color(0xFF475569)),
          bodySmall: TextStyle(color: Color(0xFF94A3B8)),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? _primaryLight : null,
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Color(0xFF1E293B),
          contentTextStyle: TextStyle(color: Colors.white),
        ),
      );

  // ─────────── DARK ───────────
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryDark,
          brightness: Brightness.dark,
          primary: _primaryDark,
          onPrimary: Colors.white,
          surface: const Color(0xFF1E2235),
          onSurface: const Color(0xFFF1F5F9),
        ),
        scaffoldBackgroundColor: const Color(0xFF111827),
        cardColor: const Color(0xFF1E2235),
        dividerColor: const Color(0xFF374151),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E2235),
          foregroundColor: Color(0xFFF1F5F9),
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1E2235),
          selectedItemColor: _primaryDark,
          unselectedItemColor: Color(0xFF6B7280),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2D3748),
          hintStyle: const TextStyle(color: Color(0xFF6B7280)),
          labelStyle: const TextStyle(color: Color(0xFF9CA3AF)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF374151)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF374151)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _primaryDark, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFC8181)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFC8181), width: 1.5),
          ),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(color: Color(0xFFF1F5F9), fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(color: Color(0xFFF1F5F9), fontWeight: FontWeight.bold),
          headlineSmall: TextStyle(color: Color(0xFFF1F5F9), fontWeight: FontWeight.bold),
          titleLarge: TextStyle(color: Color(0xFFF1F5F9), fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: Color(0xFFF1F5F9), fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: Color(0xFFF1F5F9)),
          bodyMedium: TextStyle(color: Color(0xFF94A3B8)),
          bodySmall: TextStyle(color: Color(0xFF6B7280)),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? _primaryDark : null,
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Color(0xFF1E2235),
          contentTextStyle: TextStyle(color: Color(0xFFF1F5F9)),
        ),
      );
}
