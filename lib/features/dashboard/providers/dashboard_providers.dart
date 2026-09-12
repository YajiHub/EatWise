import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eatwise/core/database/app_database.dart';

final _loadedTargetsProvider = FutureProvider<Map<String, double>>((ref) async {
  return {
    'calories': await AppDatabase.getNumericSetting('target_calories', 2000),
    'protein': await AppDatabase.getNumericSetting('target_protein', 60),
    'carbs': await AppDatabase.getNumericSetting('target_carbs', 250),
    'fats': await AppDatabase.getNumericSetting('target_fats', 55),
  };
});

final targetCaloriesProvider = StateProvider<double>((ref) {
  final loaded = ref.watch(_loadedTargetsProvider);
  return loaded.valueOrNull?['calories'] ?? 2000;
});

final targetProteinProvider = StateProvider<double>((ref) {
  final loaded = ref.watch(_loadedTargetsProvider);
  return loaded.valueOrNull?['protein'] ?? 60;
});

final targetCarbsProvider = StateProvider<double>((ref) {
  final loaded = ref.watch(_loadedTargetsProvider);
  return loaded.valueOrNull?['carbs'] ?? 250;
});

final targetFatsProvider = StateProvider<double>((ref) {
  final loaded = ref.watch(_loadedTargetsProvider);
  return loaded.valueOrNull?['fats'] ?? 55;
});

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final fastingEnabledProvider = FutureProvider<bool>((ref) async {
  final v = await AppDatabase.getSetting('fasting_enabled');
  return v == 'true';
});

final userNameProvider = FutureProvider<String>((ref) async {
  final n = await AppDatabase.getSetting('profile_name');
  return (n != null && n.trim().isNotEmpty) ? n.trim() : '';
});

final logVersionProvider = StateProvider<int>((ref) => 0);

final dailyTotalsProvider = FutureProvider.family<Map<String, double>, String>((ref, dateStr) async {
  ref.watch(logVersionProvider);
  return AppDatabase.getDailyTotals(dateStr);
});
