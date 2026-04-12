import 'package:flutter/material.dart';

/// Central color definitions for Flutter Awesome UI Components.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFF08080F);
  static const Color surface = Color(0xFF12121C);
  static const Color surfaceElevated = Color(0xFF1C1C2E);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0C8);
  static const Color textMuted = Color(0xFF606080);
  static const Color accent = Color(0xFF6C63FF);
  static const Color divider = Color(0xFF252535);

  /// Gradient palettes used for demo cards.
  /// Each entry is [topColor, bottomColor].
  static const List<List<Color>> cardGradients = <List<Color>>[
    <Color>[Color(0xFF667EEA), Color(0xFF764BA2)], // Violet
    <Color>[Color(0xFFF093FB), Color(0xFFF5576C)], // Rose
    <Color>[Color(0xFF4FACFE), Color(0xFF00F2FE)], // Sky
    <Color>[Color(0xFF43E97B), Color(0xFF38F9D7)], // Mint
    <Color>[Color(0xFFFA709A), Color(0xFFFEE140)], // Sunset
    <Color>[Color(0xFFA18CD1), Color(0xFFFBC2EB)], // Lavender
    <Color>[Color(0xFFFF9A9E), Color(0xFFFECFEF)], // Blush
    <Color>[Color(0xFF0BA360), Color(0xFF3CBA92)], // Forest
  ];
}
