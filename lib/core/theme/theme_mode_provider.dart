import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eatwise/core/database/app_database.dart';

/// Mutable theme controller so the quick-toggle in the dashboard header
/// applies instantly without invalidating/re-fetching from the DB.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    final stored = await AppDatabase.getSetting('theme_mode');
    state = switch (stored) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      _ => ThemeMode.system,
    };
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await AppDatabase.setSetting('theme_mode', mode.name);
  }

  /// Flip between light and dark. System resolves to whichever is active,
  /// so toggling always lands on the opposite brightness of what's shown.
  Future<void> toggle() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await set(next);
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});
