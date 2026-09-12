import 'package:eatwise/core/database/app_database.dart';
import 'package:eatwise/features/dashboard/models/daily_summary.dart';
import 'package:eatwise/features/dashboard/models/monthly_stats.dart';
import 'package:eatwise/features/dashboard/models/weekly_stats.dart';

class DashboardRepository {
  Future<List<DailySummary>> getWeekSummaries(List<String> dates) async {
    final rows = await AppDatabase.getWeekSummaries(dates);
    return rows.map((r) => DailySummary.fromMap(r)).toList();
  }

  Future<Set<int>> getMonthLoggedDays(int year, int month) async {
    return AppDatabase.getMonthLoggedDays(year, month);
  }

  Future<Map<int, double>> getMonthDayCalories(int year, int month) async {
    return AppDatabase.getMonthDayCalories(year, month);
  }

  Future<WeeklyStats> getWeeklyStats(List<String> dates) async {
    final rows = await AppDatabase.getWeekSummaries(dates);
    final streak = await AppDatabase.getStreak(dates.last);
    return WeeklyStats.fromSummaries(rows, streak);
  }

  Future<MonthlyStats> getMonthlyStats(int year, int month) async {
    final totals = await AppDatabase.getMonthlyTotals(year, month);
    return MonthlyStats.fromTotals(totals);
  }
}
