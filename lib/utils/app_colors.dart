import 'package:flutter/material.dart';

class AppColors {
  // Primary color palette
  static const Color sunset = Color(0xFFF3CC97);
  static const Color tickleMePink = Color(0xFFF283AF);
  static const Color raspberryRose = Color(0xFFC43670);
  static const Color cherryBlossom = Color(0xFFFBD9E5);
  static const Color blush = Color(0xFFFAC4D2);
  static const Color champagne = Color(0xFFFBF4EB);
  static const Color smokeWhite = Color(0xFFF5F5F5);

  // Semantic colors
  static const Color primary = raspberryRose;
  static const Color secondary = tickleMePink;
  static const Color accent = sunset;
  static const Color background = champagne;
  static const Color surface = cherryBlossom;

  // Text colors
  static const Color textPrimary = Color(0xFF2D2D2D);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFFFFFFFF);

  // Additional colors
  static const Color navBarBackground = Color(0xFFC43670);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE53E3E);
  static const Color info = Color(0xFF2196F3);

  // Gradient combinations
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [raspberryRose, tickleMePink],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [tickleMePink, sunset],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [champagne, cherryBlossom],
  );

  static const LinearGradient roseToSunsetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [raspberryRose, sunset],
  );
}
