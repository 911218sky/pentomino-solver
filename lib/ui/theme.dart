/// App theme and color definitions
library;

import 'package:flutter/material.dart';

/// Application color palette
class AppColors {
  AppColors._();

  static const primary = Color(0xFFFB7299);
  static const primaryLight = Color(0xFFFFD1DC);
  static const primaryDark = Color(0xFFE85A7F);
  static const accent = Color(0xFF6C5CE7);
  static const background = Color(0xFFF8F9FC);
  static const card = Colors.white;
  static const cardHover = Color(0xFFFAFBFD);
  static const text = Color(0xFF1A1D26);
  static const textSecondary = Color(0xFF8B92A5);
  static const success = Color(0xFF00C48C);
  static const error = Color(0xFFFF6B6B);
  static const border = Color(0xFFE8ECF4);
  static const shadow = Color(0x0A000000);
}

/// Pentomino piece colors - vibrant modern palette
const List<Color> pieceColors = [
  Color(0xFFFF6B6B), // F - Coral Red
  Color(0xFF4ECDC4), // I - Turquoise
  Color(0xFF5B8DEE), // L - Royal Blue
  Color(0xFFFFE66D), // N - Sunny Yellow
  Color(0xFFA66CFF), // P - Vivid Purple
  Color(0xFF2ED573), // T - Emerald
  Color(0xFFFF9F43), // U - Tangerine
  Color(0xFF778CA3), // V - Steel Blue
  Color(0xFFD4A574), // W - Caramel
  Color(0xFF7BED9F), // X - Mint
  Color(0xFFFF85A2), // Y - Rose Pink
  Color(0xFF70A1FF), // Z - Sky Blue
];

/// Build app theme
ThemeData buildAppTheme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      surface: AppColors.background,
    ),
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'Segoe UI',
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.text,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.3),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
    useMaterial3: true,
  );
}
