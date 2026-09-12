import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eatwise/features/dashboard/models/weekly_stats.dart';
import 'package:eatwise/features/dashboard/providers/weekly_chart_provider.dart';

final statsProvider = FutureProvider.autoDispose<WeeklyStats>((ref) async {
  final repo = ref.watch(dashboardRepoProvider);
  final dates = ref.watch(weekDatesProvider);
  return repo.getWeeklyStats(dates);
});
