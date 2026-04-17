import 'package:flutter/material.dart';

enum AppThemeType {
  light,
  dark,
  pastel;

  String get label {
    switch (this) {
      case AppThemeType.light:
        return 'デフォルト';
      case AppThemeType.dark:
        return 'ダーク';
      case AppThemeType.pastel:
        return 'パステル';
    }
  }
}

class AppTheme {
  // --- 共通カラー設定 ---
  static const Color mintGreen = Color(0xFF2ECC71);
  static const Color skyBlue = Color(0xFF3498DB);
  static const Color deepNavy = Color(0xFF2C3E50);

  // --- デフォルト (Mint & Sky) ---
  static final light = _buildTheme(
    brightness: Brightness.light,
    primary: mintGreen,
    secondary: skyBlue,
    background: const Color(0xFFF8F9FA),
    surface: Colors.white,
    text: deepNavy,
    radius: 24.0,
  );

  // --- 真のダークモード ---
  static final dark = _buildTheme(
    brightness: Brightness.dark,
    primary: mintGreen,
    secondary: skyBlue,
    background: const Color(0xFF121212),
    surface: const Color(0xFF1E1E1E),
    text: const Color(0xFFE0E0E0),
    radius: 24.0,
  );

  // --- パステルポップ ---
  static final pastel = _buildTheme(
    brightness: Brightness.light,
    primary: const Color(0xFFF06292), // Pastel Pink
    secondary: const Color(0xFFBA68C8), // Pastel Purple
    background: const Color(0xFFF3E5F5), // Pale Lavender
    surface: Colors.white,
    text: const Color(0xFF5E35B1),
    radius: 32.0, // より丸みを強調
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color primary,
    required Color secondary,
    required Color background,
    required Color surface,
    required Color text,
    required double radius,
  }) {
    final isDark = brightness == Brightness.dark;
    
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: brightness,
        primary: primary,
        secondary: secondary,
        surface: surface,
        background: background,
        onSurface: text,
      ),
      scaffoldBackgroundColor: background,
      cardColor: surface,
      dividerColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
      canvasColor: surface,

      textTheme: TextTheme(
        bodyLarge: TextStyle(color: text, letterSpacing: 0.8),
        bodyMedium: TextStyle(color: text, letterSpacing: 0.5),
        headlineSmall: TextStyle(color: text, fontWeight: FontWeight.bold, letterSpacing: 1.0),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? surface : primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: isDark ? 0 : 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: isDark ? Colors.white.withOpacity(0.05) : primary.withOpacity(0.1),
        selectedColor: primary,
        secondarySelectedColor: secondary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: TextStyle(color: text, fontSize: 13),
        secondaryLabelStyle: const TextStyle(color: Colors.white, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius * 0.8)),
      ),

      dialogTheme: DialogTheme(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius * 1.2)),
        titleTextStyle: TextStyle(color: text, fontSize: 20, fontWeight: FontWeight.bold),
        contentTextStyle: TextStyle(color: text, fontSize: 14),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(radius * 1.3))),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius * 0.8),
          borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius * 0.8),
          borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius * 0.8),
          borderSide: BorderSide(color: primary, width: 2),
        ),
      ),
    );
  }

  static ThemeData fromType(AppThemeType type) {
    switch (type) {
      case AppThemeType.light:
        return light;
      case AppThemeType.dark:
        return dark;
      case AppThemeType.pastel:
        return pastel;
    }
  }
}
