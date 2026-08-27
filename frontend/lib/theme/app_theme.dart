import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color text = Color(0xFF1a1a2e);
  static const Color tint = Color(0xFF663d99);
  static const Color background = Color(0xFFf0f5f7);
  static const Color foreground = Color(0xFF1a1a2e);
  static const Color card = Color(0xFFffffff);
  static const Color cardForeground = Color(0xFF1a1a2e);
  
  static const Color primary = Color(0xFF663d99);
  static const Color primaryDark = Color(0xFF422969);
  static const Color primaryDeep = Color(0xFF26266a);
  static const Color primaryForeground = Color(0xFFffffff);
  
  static const Color secondary = Color(0xFFede8f5);
  static const Color secondaryForeground = Color(0xFF422969);
  
  static const Color muted = Color(0xFFede8f5);
  static const Color mutedForeground = Color(0xFF7c6f9a);
  
  static const Color accent = Color(0xFFf0c230);
  static const Color accentDark = Color(0xFFc9a01f);
  static const Color accentForeground = Color(0xFF1a1a2e);
  
  static const Color destructive = Color(0xFFEF4444);
  static const Color destructiveForeground = Color(0xFFFFFFFF);
  
  static const Color border = Color(0xFFd9d3e8);
  static const Color input = Color(0xFFc4b8da);
  
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
  static const Color error = Color(0xFFdc2626);
  static const Color errorBg = Color(0xFFfef2f2);

  static const Color white = Color(0xFFffffff);

  static const double radius = 12.0;
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.primaryForeground,
        secondary: AppColors.accent,
        onSecondary: AppColors.accentForeground,
        surface: AppColors.background,
        onSurface: AppColors.text,
        error: AppColors.error,
        onError: AppColors.destructiveForeground,
      ),
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: GoogleFonts.ibmPlexSansTextTheme().apply(
        bodyColor: AppColors.text,
        displayColor: AppColors.text,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.text,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.ibmPlexSans(
          color: AppColors.text,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radius),
          borderSide: const BorderSide(color: AppColors.input, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radius),
          borderSide: const BorderSide(color: AppColors.input, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radius),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radius),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: GoogleFonts.ibmPlexSans(color: AppColors.mutedForeground),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.accentForeground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radius + 2), // 14 for buttons
          ),
          textStyle: GoogleFonts.ibmPlexSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radius + 8), // 20 for cards
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
    );
  }
}
