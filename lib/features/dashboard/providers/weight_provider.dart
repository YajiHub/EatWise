import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eatwise/core/database/app_database.dart';
import 'package:eatwise/features/dashboard/data/weight_repository.dart';
import 'package:eatwise/features/dashboard/models/weight_entry.dart';

final weightRepositoryProvider = Provider<WeightRepository>((ref) => WeightRepository());

final weightEntriesProvider = FutureProvider.autoDispose<List<WeightEntry>>((ref) async {
  final repo = ref.watch(weightRepositoryProvider);
  return repo.getHistory(limit: 30);
});

final latestWeightProvider = FutureProvider.autoDispose<WeightEntry?>((ref) async {
  final repo = ref.watch(weightRepositoryProvider);
  return repo.getLatest();
});

final previousWeightProvider = FutureProvider.autoDispose<WeightEntry?>((ref) async {
  final entries = ref.watch(weightEntriesProvider).valueOrNull;
  if (entries != null && entries.length >= 2) return entries[1];
  return null;
});

final heightCmProvider = FutureProvider.autoDispose<double?>((ref) {
  ref.keepAlive();
  return AppDatabase.getNumericSetting('weight_height_cm', 0);
});

final goalWeightProvider = FutureProvider.autoDispose<double?>((ref) async {
  ref.keepAlive();
  final v = await AppDatabase.getNumericSetting('goal_weight_kg', 0);
  return v > 0 ? v : null;
});

final weightVersionProvider = StateProvider<int>((ref) => 0);

Future<void> insertWeightEntry(WidgetRef ref, WeightEntry entry) async {
  final repo = ref.read(weightRepositoryProvider);
  await repo.insert(entry);
  if (entry.heightCm != null) {
    await AppDatabase.setSetting('weight_height_cm', entry.heightCm!.toString());
  }
  ref.invalidate(weightEntriesProvider);
  ref.invalidate(latestWeightProvider);
  ref.invalidate(previousWeightProvider);
  if (entry.heightCm != null) ref.invalidate(heightCmProvider);
}
