import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const Color primary = Color(0xFF34D399);
  static const Color secondary = Color(0xFF242426);
  static const Color background = Color(0xFF1B1B1E);
  static const Color error = Color(0xFFC43B3B);
  static const Color blue = Color(0xFF646AF2);
  static const Color pink = Color(0xFFE84DA3);
  static const Color orange = Color(0xFFF04E43);
  static const Color yellow = Color(0xFFF0F043);

  static Color gradientOverlay(Color color, {double opacity = 0.85}) =>
      color.withAlpha((opacity * 255).round());
}
