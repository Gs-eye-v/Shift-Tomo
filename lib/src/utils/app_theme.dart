import 'package:flutter/material.dart';

enum AppThemeType {
  dark,
  light,
  pop,
  line;

  String get label {
    switch (this) {
      case AppThemeType.dark:
        return 'ダーク';
      case AppThemeType.light:
        return 'ライト';
      case AppThemeType.pop:
        return 'ポップ';
      case AppThemeType.line:
        return 'ライン風';
    }
  }
}

class AppTheme {
  static final dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: Colors.blueGrey,
    scaffoldBackgroundColor: const Color(0xFF121212),
    cardColor: const Color(0xFF1E1E1E),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
    ),
  );

  static final light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorSchemeSeed: const Color(0xFFD81B60), // Vibrant Pink-Purple
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFD81B60),
      foregroundColor: Colors.white,
    ),
  );

  static final pop = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorSchemeSeed: const Color(0xFFFF00FF), // Magenta/Pop
    scaffoldBackgroundColor: const Color(0xFFFFF0FF),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFF00FF),
      foregroundColor: Colors.white,
    ),
  );

  static final line = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorSchemeSeed: const Color(0xFF00B900),
    scaffoldBackgroundColor: const Color(0xFFE8F5E9),
  );

  static ThemeData fromType(AppThemeType type) {
    switch (type) {
      case AppThemeType.dark:
        return dark;
      case AppThemeType.light:
        return light;
      case AppThemeType.pop:
        return pop;
      case AppThemeType.line:
        return line;
    }
  }
}
