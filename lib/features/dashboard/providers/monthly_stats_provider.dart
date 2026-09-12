import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eatwise/features/dashboard/models/monthly_stats.dart';
import 'package:eatwise/features/dashboard/providers/weekly_chart_provider.dart';
import 'package:eatwise/features/dashboard/presentation/screens/dashboard_screen.dart';

final monthlyStatsProvider = FutureProvider<MonthlyStats>((ref) async {
  ref.watch(logVersionProvider);
  final repo = ref.watch(dashboardRepoProvider);
  final now = DateTime.now();
  return repo.getMonthlyStats(now.year, now.month);
});
