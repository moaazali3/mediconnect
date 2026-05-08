/// Shared helper extension so any widget can call
///   context.cardColor, context.onSurface, context.isDark, etc.
/// Import this once and eliminate all the Theme.of(context).X repetition.
library app_theme_ext;

import 'package:flutter/material.dart';

extension AppThemeContext on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get cs => Theme.of(this).colorScheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get cardBg => Theme.of(this).cardColor;
  Color get scaffoldBg => Theme.of(this).scaffoldBackgroundColor;
  Color get onSurface => Theme.of(this).colorScheme.onSurface;
  Color get subText => Theme.of(this).colorScheme.onSurface.withOpacity(0.55);
  Color get dividerCol => Theme.of(this).dividerColor;
  Color get inputFill => isDark ? const Color(0xFF2D3748) : Colors.white;
  Color get filterChipBg => isDark ? const Color(0xFF1E2235) : Colors.white;
  Color get filterChipBorder => isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0);
}
