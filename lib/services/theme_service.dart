import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Singleton ChangeNotifier that holds and persists the app's ThemeMode.
class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Call once in main() before runApp to restore saved preference.
  /// If the user never manually set the theme, we follow the system.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final hasUserChoice = prefs.containsKey('is_dark_mode');
    if (hasUserChoice) {
      final isDark = prefs.getBool('is_dark_mode') ?? false;
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      debugPrint("[ThemeService] Initialized with saved choice: ${_themeMode.name}");
    } else {
      // First launch — follow system brightness
      _themeMode = ThemeMode.system;
      debugPrint("[ThemeService] Initialized with system default.");
    }
    // No notifyListeners() here; called before the widget tree exists.
  }

  /// Toggle between light and dark, then persist the choice.
  Future<void> toggleTheme() async {
    // If currently following system, resolve actual mode first
    if (_themeMode == ThemeMode.system) {
      final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      _themeMode = brightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
    } else {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    }
    
    debugPrint("[ThemeService] Theme toggled to: ${_themeMode.name}");
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', _themeMode == ThemeMode.dark);
    notifyListeners();
  }
}
