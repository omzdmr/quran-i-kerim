import 'package:flutter/material.dart';

class AppTheme {
  static const _accent = Color(0xFF70C9A9);
  static const _bg = Color(0xFF0D0E0D);
  static const _surface = Color(0xFF1E1D1D);
  static const _surface2 = Color(0xFF2A2929);

  static ThemeData get light => dark;

  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: _accent,
      secondary: _accent,
      surface: _surface,
      onSurface: Color(0xFFF5F5F2),
      onPrimary: Color(0xFF07130F),
      surfaceContainerHighest: _surface2,
      outline: Color(0xFF454545),
    );

    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: _bg,
      fontFamilyFallback: const ['SF Pro Display', 'Arial', 'sans-serif'],
      appBarTheme: const AppBarTheme(
        backgroundColor: _bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      dividerColor: const Color(0xFF262626),
      cardTheme: const CardThemeData(
        color: _surface,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -1.2),
        headlineMedium: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.8),
        titleLarge: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3),
      ),
    );
  }
}
