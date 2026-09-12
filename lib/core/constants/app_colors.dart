import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary — Emerald Green (brand)
  static const primary = Color(0xFF1DB954);
  static const primaryLight = Color(0xFF2FE574);
  static const primaryDark = Color(0xFF159C42);

  // Primary adaptations for inverted backgrounds
  static const onPrimaryLight = Color(0xFFFFFFFF);
  static const onPrimaryDark = Color(0xFF003318);

  // Secondary — Teal (companion to emerald)
  static const secondary = Color(0xFF0D9488);
  static const secondaryLight = Color(0xFF14B8A6);
  static const secondaryDark = Color(0xFF0F766E);

  // Tertiary — Amber (energy)
  static const tertiary = Color(0xFFD97706);
  static const tertiaryLight = Color(0xFFF59E0B);

  // Neutrals
  static const backgroundLight = Color(0xFFF6FAFF);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceDark = Color(0xFF0B1326);
  static const surfaceContainerDark = Color(0xFF131C32);
  static const textPrimaryLight = Color(0xFF0B1326);
  static const textSecondaryLight = Color(0xFF5A6578);
  static const textPrimaryDark = Color(0xFFE8EDF5);
  static const textSecondaryDark = Color(0xFF9BA6BC);

  // Macro colors — vibrant, high-contrast for charts
  static const protein = Color(0xFF3B82F6); // Blue
  static const carbs = Color(0xFFF97316); // Orange
  static const fats = Color(0xFFEAB308); // Yellow

  // Fasting — softer, readable in both modes
  static const fasting = Color(0xFF6366F1);
  static const eating = Color(0xFFF59E0B);
}
