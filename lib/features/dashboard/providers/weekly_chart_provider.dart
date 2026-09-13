import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:eatwise/features/dashboard/data/dashboard_repository.dart';
import 'package:eatwise/features/dashboard/models/daily_summary.dart';
import 'package:eatwise/features/dashboard/providers/dashboard_providers.dart';

final dashboardRepoProvider = Provider<DashboardRepository>((ref) => DashboardRepository());

/// Week offset relative to current week (0 = current week, -1 = last week, etc.)
final hubWeekOffsetProvider = StateProvider<int>((ref) => 0);

List<String> _weekDates(DateTime anchor) {
  final monday = anchor.subtract(Duration(days: anchor.weekday - 1));
  return List.generate(7, (i) {
    final d = monday.add(Duration(days: i));
    return DateFormat('yyyy-MM-dd').format(d);
  });
}

final weekDatesProvider = Provider.autoDispose<List<String>>((ref) {
  final offset = ref.watch(hubWeekOffsetProvider);
  final now = DateTime.now();
  final anchor = now.add(Duration(days: offset * 7));
  return _weekDates(anchor);
});

final weeklyChartProvider = FutureProvider.autoDispose<List<DailySummary>>((ref) async {
  ref.watch(logVersionProvider);
  final repo = ref.watch(dashboardRepoProvider);
  final dates = ref.watch(weekDatesProvider);
  return repo.getWeekSummaries(dates);
});
