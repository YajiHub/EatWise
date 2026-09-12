import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eatwise/core/database/app_database.dart';

/// Async provider that loads all settings at boot and exposes them.
final appSettingsProvider = FutureProvider<Map<String, String>>((ref) async {
  return _loadAllSettings();
});

Future<Map<String, String>> _loadAllSettings() async {
  final keys = [
    'target_calories', 'target_protein', 'target_carbs', 'target_fats',
    'fasting_schedule', 'fasting_start_hour', 'fasting_start_minute',
    'fasting_end_hour', 'fasting_end_minute',
  ];
  final map = <String, String>{};
  for (final k in keys) {
    final v = await AppDatabase.getSetting(k);
    if (v != null) map[k] = v;
  }
  return map;
}
