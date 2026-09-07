import 'package:flutter/material.dart';

class AppTheme {
  static const _darkAccent = Color(0xFF70C9A9);
  static const _lightAccent = Color(0xFF126B52);

  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: _lightAccent,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFD7F0E5),
      onPrimaryContainer: Color(0xFF0A3B2D),
      secondary: Color(0xFF53675F),
      surface: Color(0xFFFCFBF8),
      onSurface: Color(0xFF1B1C1A),
      onSurfaceVariant: Color(0xFF696C67),
      surfaceContainer: Color(0xFFF0EFEA),
      surfaceContainerHighest: Color(0xFFE7E6E0),
      outline: Color(0xFFC6C8C2),
    );

    return _buildTheme(
      scheme: scheme,
      scaffoldBackground: const Color(0xFFF9F8F4),
      dividerColor: const Color(0xFFE3E2DD),
      cardColor: const Color(0xFFF0EFEA),
    );
  }

  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: _darkAccent,
      onPrimary: Color(0xFF07130F),
      primaryContainer: Color(0xFF1D4438),
      onPrimaryContainer: Color(0xFFD8F6EA),
      secondary: _darkAccent,
      surface: Color(0xFF1E1D1D),
      onSurface: Color(0xFFF5F5F2),
      onSurfaceVariant: Color(0xFFB8BAB5),
      surfaceContainer: Color(0xFF211F1F),
      surfaceContainerHighest: Color(0xFF2A2929),
      outline: Color(0xFF454545),
    );

    return _buildTheme(
      scheme: scheme,
      scaffoldBackground: const Color(0xFF0D0E0D),
      dividerColor: const Color(0xFF262626),
      cardColor: const Color(0xFF1E1D1D),
    );
  }

  static ThemeData _buildTheme({
    required ColorScheme scheme,
    required Color scaffoldBackground,
    required Color dividerColor,
    required Color cardColor,
  }) {
    return ThemeData(
      brightness: scheme.brightness,
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBackground,
      fontFamilyFallback: const ['SF Pro Display', 'Arial', 'sans-serif'],
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBackground,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 21,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.4,
        ),
      ),
      dividerColor: dividerColor,
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.2,
        ),
        headlineMedium: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.8,
        ),
        titleLarge: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
        bodyLarge: TextStyle(color: scheme.onSurface),
        bodyMedium: TextStyle(color: scheme.onSurface),
      ),
    );
  }
}
