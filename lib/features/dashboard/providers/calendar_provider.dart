import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eatwise/features/dashboard/providers/weekly_chart_provider.dart';

final calendarProvider = FutureProvider.autoDispose.family<Map<int, double>, (int, int)>((ref, args) async {
  final repo = ref.watch(dashboardRepoProvider);
  return repo.getMonthDayCalories(args.$1, args.$2);
});
