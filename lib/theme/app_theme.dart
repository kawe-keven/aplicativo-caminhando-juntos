import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF003A1F);
  static const Color primaryContainer = Color(0xFF135232);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF86C49B);
  
  static const Color secondaryColor = Color(0xFF376382);
  static const Color secondaryContainer = Color(0xFFAEDAFE);
  
  static const Color tertiaryColor = Color(0xFF4E2700);
  static const Color tertiaryContainer = Color(0xFF6F3A00);
  static const Color onTertiary = Color(0xFFFFFFFF);
  
  static const Color backgroundColor = Color(0xFFF9F9FF);
  static const Color surfaceColor = Color(0xFFF9F9FF);
  static const Color onSurface = Color(0xFF141B2B);
  static const Color onSurfaceVariant = Color(0xFF404942);
  
  static const Color surfaceContainerHigh = Color(0xFFE1E8FD);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  
  static const Color errorColor = Color(0xFFBA1A1A);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        onPrimary: onPrimary,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondaryColor,
        secondaryContainer: secondaryContainer,
        tertiary: tertiaryColor,
        tertiaryContainer: tertiaryContainer,
        onTertiary: onTertiary,
        error: errorColor,
        surface: surfaceColor,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
      ),
      textTheme: GoogleFonts.lexendTextTheme().copyWith(
        displayLarge: GoogleFonts.lexend(
          fontSize: 40,
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
        displayMedium: GoogleFonts.lexend(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
        headlineLarge: GoogleFonts.lexend(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
        headlineMedium: GoogleFonts.lexend(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        headlineSmall: GoogleFonts.lexend(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        titleLarge: GoogleFonts.lexend(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: primaryColor,
          letterSpacing: 0.4,
        ),
        bodyLarge: GoogleFonts.lexend(
          fontSize: 20,
          fontWeight: FontWeight.w400,
          color: onSurface,
          height: 1.6,
        ),
        bodyMedium: GoogleFonts.lexend(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          color: onSurface,
          height: 1.5,
        ),
        labelLarge: GoogleFonts.lexend(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: onPrimary,
          letterSpacing: 0.4,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryContainer,
          foregroundColor: onPrimary,
          minimumSize: const Size(double.infinity, 64),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.lexend(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}
