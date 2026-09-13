import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary — Electric Emerald (brand & metabolic target)
  static const primary = Color(0xFF00E676);
  static const primaryLight = Color(0xFF75FF9E);
  static const primaryDark = Color(0xFF006D35);
  static const primaryGlow = Color(0x5900E676); // 35% glow bloom

  // Primary adaptations for inverted backgrounds
  static const onPrimaryLight = Color(0xFFFFFFFF);
  static const onPrimaryDark = Color(0xFF003918);

  // Secondary — Cobalt / Athletic Blue
  static const secondary = Color(0xFF3B82F6);
  static const secondaryLight = Color(0xFFADC6FF);
  static const secondaryDark = Color(0xFF0566D9);

  // Tertiary — Flame Orange / Energy
  static const tertiary = Color(0xFFF97316);
  static const tertiaryLight = Color(0xFFFFB995);

  // Neutrals — Athletic Obsidian System
  static const canvasDark = Color(0xFF080C14);
  static const backgroundLight = Color(0xFFF6FAFF);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceDark = Color(0xFF0F131C);
  static const surfaceCard = Color(0xFF181C24);
  static const surfaceContainerDark = Color(0xFF1C2028);
  static const surfaceContainerHigh = Color(0xFF262A33);
  static const surfaceContainerHighest = Color(0xFF31353E);

  // 1px Precision Ghost Borders
  static const surfaceCardBorder = Color(0x14FFFFFF); // 8% white
  static const surfaceCardBorderActive = Color(0x33FFFFFF); // 20% white

  // Text
  static const textPrimaryLight = Color(0xFF0B1326);
  static const textSecondaryLight = Color(0xFF5A6578);
  static const textPrimaryDark = Color(0xFFDFE2EE);
  static const textSecondaryDark = Color(0xFFBACBB9);
  static const textMutedDark = Color(0xFF64748B);

  // Macro colors — athletic telemetry
  static const protein = Color(0xFF3B82F6); // Electric Cobalt
  static const proteinLight = Color(0xFFADC6FF);
  static const carbs = Color(0xFFF97316); // Sunset Flame
  static const carbsLight = Color(0xFFFFB995);
  static const fats = Color(0xFFFACC15); // Solar Amber
  static const fatsLight = Color(0xFFFFDECF);

  // Fasting — circadian telemetry
  static const fasting = Color(0xFF818CF8); // Indigo Moon
  static const fastingGlow = Color(0x33818CF8);
  static const eating = Color(0xFFF59E0B);
}
