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
    return _buildTheme(
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
    );
  }

  static ThemeData get highContrastTheme {
    return _buildTheme(
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: Colors.yellow,
        onPrimary: Colors.black,
        secondary: Colors.cyanAccent,
        onSecondary: Colors.black,
        tertiary: Colors.orangeAccent,
        onTertiary: Colors.black,
        surface: Colors.black,
        onSurface: Colors.white,
        error: Colors.redAccent,
        onError: Colors.white,
      ),
      isHighContrast: true,
    );
  }

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    bool isHighContrast = false,
  }) {
    final textTheme = GoogleFonts.lexendTextTheme().copyWith(
      displayLarge: GoogleFonts.lexend(
        fontSize: 40,
        fontWeight: FontWeight.w800,
        color: colorScheme.onSurface,
      ),
      headlineLarge: GoogleFonts.lexend(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: colorScheme.onSurface,
      ),
      headlineMedium: GoogleFonts.lexend(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      titleLarge: GoogleFonts.lexend(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: isHighContrast ? colorScheme.primary : colorScheme.primary,
        letterSpacing: 0.4,
      ),
      bodyLarge: GoogleFonts.lexend(
        fontSize: 20,
        fontWeight: isHighContrast ? FontWeight.w700 : FontWeight.w400,
        color: colorScheme.onSurface,
        height: 1.6,
      ),
      bodyMedium: GoogleFonts.lexend(
        fontSize: 18,
        fontWeight: isHighContrast ? FontWeight.w600 : FontWeight.w400,
        color: colorScheme.onSurface,
        height: 1.5,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      cardTheme: CardThemeData(
        color: isHighContrast ? Colors.black : colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isHighContrast
              ? const BorderSide(color: Colors.white, width: 2.0)
              : BorderSide.none,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size(double.infinity, 64),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isHighContrast
                ? const BorderSide(color: Colors.white, width: 3.0)
                : BorderSide.none,
          ),
          textStyle: GoogleFonts.lexend(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}
