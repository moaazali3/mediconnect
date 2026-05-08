import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Singleton ChangeNotifier that holds and persists the app's ThemeMode.
class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Call once in main() before runApp to restore saved preference.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('is_dark_mode') ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    // No notifyListeners() here; called before the widget tree exists.
  }

  /// Toggle between light and dark, then persist the choice.
  Future<void> toggleTheme() async {
    _themeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', _themeMode == ThemeMode.dark);
    notifyListeners();
  }
}
