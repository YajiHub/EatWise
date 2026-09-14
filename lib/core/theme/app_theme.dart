import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static const _cardRadius = BorderRadius.all(Radius.circular(12));
  static const _buttonRadius = BorderRadius.all(Radius.circular(10));
  static const _inputRadius = BorderRadius.all(Radius.circular(12));

  static final ThemeData lightTheme = _buildLight();
  static final ThemeData darkTheme = _buildDark();

  static ThemeData _buildLight() {
    final cs = ColorScheme(
      brightness: Brightness.light,
      primary: const Color(0xFF1DB954),
      onPrimary: const Color(0xFFFFFFFF),
      primaryContainer: const Color(0xFFB8F0CB),
      onPrimaryContainer: const Color(0xFF003318),
      secondary: const Color(0xFF0D9488),
      onSecondary: const Color(0xFFFFFFFF),
      secondaryContainer: const Color(0xFFCFF6F2),
      onSecondaryContainer: const Color(0xFF00201E),
      tertiary: const Color(0xFFD97706),
      onTertiary: const Color(0xFFFFFFFF),
      tertiaryContainer: const Color(0xFFFCE4B6),
      onTertiaryContainer: const Color(0xFF2C1900),
      error: const Color(0xFFBA1A1A),
      onError: const Color(0xFFFFFFFF),
      errorContainer: const Color(0xFFFFDAD6),
      onErrorContainer: const Color(0xFF410002),
      surface: const Color(0xFFF6FAFF),
      onSurface: const Color(0xFF0B1326),
      surfaceContainerHighest: const Color(0xFFDDE7F2),
      onSurfaceVariant: const Color(0xFF5A6578),
      outline: const Color(0xFF7A8294),
      outlineVariant: const Color(0xFFDDE7F2),
    );
    return _build(cs);
  }

  static ThemeData _buildDark() {
    final cs = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimaryDark,
      primaryContainer: const Color(0xFF006D35),
      onPrimaryContainer: AppColors.primaryLight,
      secondary: AppColors.secondary,
      onSecondary: const Color(0xFF002E6A),
      secondaryContainer: const Color(0xFF0566D9),
      onSecondaryContainer: const Color(0xFFE6ECFF),
      tertiary: AppColors.tertiary,
      onTertiary: const Color(0xFF552100),
      tertiaryContainer: const Color(0xFF8D3B00),
      onTertiaryContainer: const Color(0xFFFFB995),
      error: const Color(0xFFFFB4AB),
      onError: const Color(0xFF690005),
      errorContainer: const Color(0xFF93000A),
      onErrorContainer: const Color(0xFFFFDAD6),
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textPrimaryDark,
      surfaceContainerLowest: AppColors.canvasDark,
      surfaceContainerLow: AppColors.surfaceCard,
      surfaceContainer: AppColors.surfaceContainerDark,
      surfaceContainerHigh: AppColors.surfaceContainerHigh,
      surfaceContainerHighest: AppColors.surfaceContainerHighest,
      onSurfaceVariant: AppColors.textSecondaryDark,
      outline: const Color(0xFF859585),
      outlineVariant: const Color(0xFF3B4A3D),
    );
    return _build(cs);
  }

  static ThemeData _build(ColorScheme cs) {
    final isDark = cs.brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      brightness: cs.brightness,
      scaffoldBackgroundColor: isDark ? AppColors.canvasDark : cs.surface,

      textTheme: GoogleFonts.interTextTheme(_textTheme(isDark)),
      fontFamily: GoogleFonts.inter().fontFamily,

      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: isDark ? AppColors.canvasDark : cs.surface,
        foregroundColor: cs.onSurface,
        iconTheme: IconThemeData(color: cs.onSurface, size: 22),
        titleTextStyle: GoogleFonts.inter(
          color: cs.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 68,
        backgroundColor: isDark ? AppColors.surfaceDark : cs.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: isDark ? AppColors.primary.withValues(alpha: 0.15) : cs.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontFamily: 'Inter',
            color: selected ? (isDark ? AppColors.primary : cs.primary) : cs.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: selected ? 26 : 22,
            color: selected ? (isDark ? AppColors.primary : cs.primary) : cs.onSurfaceVariant,
          );
        }),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? AppColors.surfaceCard : cs.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          side: isDark
              ? const BorderSide(color: AppColors.surfaceCardBorder, width: 1)
              : BorderSide.none,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          minimumSize: const Size(64, 52),
          shape: const RoundedRectangleBorder(borderRadius: _buttonRadius),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.2, fontFamily: 'Inter'),
          elevation: 0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primaryContainer,
          foregroundColor: cs.onPrimaryContainer,
          minimumSize: const Size(64, 52),
          shape: const RoundedRectangleBorder(borderRadius: _buttonRadius),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: const RoundedRectangleBorder(borderRadius: _buttonRadius),
          side: BorderSide(color: cs.outline.withValues(alpha: 0.5)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? cs.surfaceContainerHighest.withValues(alpha: 0.5)
            : cs.surfaceContainerHighest.withValues(alpha: 0.4),
        border: OutlineInputBorder(borderRadius: _inputRadius, borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: _inputRadius, borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.2))),
        focusedBorder: OutlineInputBorder(borderRadius: _inputRadius, borderSide: BorderSide(color: cs.primary, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: _inputRadius, borderSide: BorderSide(color: cs.error)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(color: cs.onSurfaceVariant, fontFamily: 'Inter'),
        hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontFamily: 'Inter'),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: cs.surfaceContainerHighest,
        selectedColor: cs.primaryContainer,
        labelStyle: const TextStyle(fontSize: 12, fontFamily: 'Inter'),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide.none,
      ),

      dividerTheme: DividerThemeData(color: cs.outlineVariant.withValues(alpha: 0.3), thickness: 1, space: 1),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        modalElevation: 4,
        elevation: 0,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: _cardRadius),
        titleTextStyle: TextStyle(color: cs.onSurface, fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Inter'),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentTextStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500),
      ),

      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? cs.onPrimary : cs.outline),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? cs.primary.withValues(alpha: 0.7) : cs.surfaceContainerHighest),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: cs.primary,
        linearTrackColor: cs.primaryContainer,
        circularTrackColor: cs.primaryContainer,
      ),
    );
  }

  static TextTheme _textTheme(bool isDark) {
    final base = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final muted = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return TextTheme(
      displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.w700, color: base, letterSpacing: -1.5),
      displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w700, color: base, letterSpacing: -0.5),
      displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: base),
      headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: base, letterSpacing: -0.5),
      headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: base),
      headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: base),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: base, letterSpacing: -0.2),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: base),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: base),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: base),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: base),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: muted),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: base, letterSpacing: 0.1),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: muted, letterSpacing: 0.5),
      labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: muted, letterSpacing: 0.5),
    );
  }
}
