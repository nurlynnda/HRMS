import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colors and text styles pulled directly from the HRMS design mockup.
class AppColors {
  static const primary = Color(0xFF10B981);
  static const primaryDark = Color(0xFF059669);
  static const background = Color(0xFFF1F5F9);
  static const cardBackground = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFF94A3B8);
  static const danger = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const border = Color(0xFFE2E8F0);
  static const primaryTint = Color(0xFFECFDF5);
  static const primaryHighlight = Color(0xFF6EE7B7);
  static const ringTrack = Color(0xFFEEF2F6);
}

class AppTheme {
  static ThemeData get themeData {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();
    return ThemeData(
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        surface: AppColors.background,
      ),
      textTheme: baseTextTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        backgroundColor: AppColors.cardBackground,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
