import 'package:eatwise/core/database/app_database.dart';
import 'package:eatwise/features/dashboard/models/weight_entry.dart';

class WeightRepository {
  Future<List<WeightEntry>> getHistory({int limit = 30}) async {
    final rows = await AppDatabase.getWeightHistory(limit: limit);
    return rows.map((r) => WeightEntry.fromMap(r)).toList();
  }

  Future<WeightEntry?> getLatest() async {
    final row = await AppDatabase.getLatestWeight();
    return row != null ? WeightEntry.fromMap(row) : null;
  }

  Future<WeightEntry?> getForDate(String date) async {
    final row = await AppDatabase.getWeightForDate(date);
    return row != null ? WeightEntry.fromMap(row) : null;
  }

  Future<void> insert(WeightEntry entry) async {
    await AppDatabase.insertWeight(
      date: entry.date,
      weightKg: entry.weightKg,
      heightCm: entry.heightCm,
    );
  }

  Future<bool> hasEntryOnDate(String date) async {
    return AppDatabase.hasWeightOnDate(date);
  }
}
