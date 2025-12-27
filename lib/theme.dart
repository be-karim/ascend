import 'package:flutter/material.dart';

class AscendTheme {
  static const Color background = Color(0xFF05070A); // Deep Void
  static const Color surface = Color(0xFF0F1522);    // Panel
  static const Color primary = Color(0xFFFF3D81);    // Neon Pink
  static const Color secondary = Color(0xFF00E5FF);  // Cyan
  static const Color accent = Color(0xFF7CFF00);     // Tech Green
  static const Color text = Color(0xFFF5F7FF);
  static const Color textDim = Color(0xFF64748B);    // Muted Slate

  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        tertiary: accent,
        surface: surface,
        error: Color(0xFFFF2A6D),
      ),
      fontFamily: 'Roboto', // Fallback
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: text, 
          fontWeight: FontWeight.w900, 
          letterSpacing: 1.5,
          fontSize: 32,
        ),
        displayMedium: TextStyle(
          color: text,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          fontSize: 24,
        ),
        titleLarge: TextStyle(
          color: text,
          fontWeight: FontWeight.bold,
          fontSize: 20,
          letterSpacing: 0.5,
        ),
        bodyLarge: TextStyle(color: text, fontSize: 16),
        bodyMedium: TextStyle(color: textDim, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface.withValues(alpha: 0.7),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
    );
  }
}
