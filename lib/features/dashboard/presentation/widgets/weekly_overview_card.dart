import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eatwise/features/dashboard/providers/weekly_chart_provider.dart';
import 'package:eatwise/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:eatwise/core/constants/app_colors.dart';

class WeeklyOverviewCard extends ConsumerWidget {
  const WeeklyOverviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartAsync = ref.watch(weeklyChartProvider);
    final summaries = chartAsync.valueOrNull ?? [];
    final dates = ref.watch(weekDatesProvider);
    final targetCal = ref.watch(targetCaloriesProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final today = DateTime.now();

    // Build a map of date→calories for quick lookup
    final calByDate = <String, double>{};
    for (final s in summaries) {
      calByDate[s.date] = s.totalCalories;
    }

    double weekTotal = 0;
    for (final d in dates) {
      final cal = calByDate[d] ?? 0;
      weekTotal += cal;
    }

    final weekBudget = targetCal * 7;
    final remaining = weekBudget - weekTotal;
    final isOvershoot = remaining < 0;

    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text('This Week', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 10),
            ...List.generate(7, (i) {
              final dateStr = dates[i];
              final cal = calByDate[dateStr] ?? 0;
              final ratio = targetCal > 0 ? (cal / targetCal).clamp(0.0, 1.0) : 0.0;
              final dt = DateTime.tryParse(dateStr);
              final isFutureDate = dt != null && dt.isAfter(today);
              final isSelectedDay = dt != null && selectedDate.year == dt.year && selectedDate.month == dt.month && selectedDate.day == dt.day;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: GestureDetector(
                  onTap: isFutureDate ? null : () {
                    if (dt != null) ref.read(selectedDateProvider.notifier).state = dt;
                  },
                  child: Row(
                    children: [
                      SizedBox(
                        width: 36,
                        child: Text(
                          dayNames[i],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelectedDay ? FontWeight.w700 : FontWeight.w500,
                            color: isSelectedDay ? AppColors.primary : Colors.grey.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 48,
                        child: Text(
                          isFutureDate ? '-' : cal.toStringAsFixed(0),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isFutureDate ? Colors.grey.shade400 : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: isFutureDate
                            ? Container(height: 8)
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: ratio,
                                  minHeight: 8,
                                  backgroundColor: cal <= targetCal
                                      ? Colors.green.withValues(alpha: 0.15)
                                      : Colors.red.withValues(alpha: 0.15),
                                  color: cal <= targetCal ? Colors.greenAccent : Colors.redAccent,
                                ),
                              ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 52,
                        child: Text(
                          isFutureDate ? '' : '/ ${targetCal.toStringAsFixed(0)}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const Divider(height: 18),
            Row(
              children: [
                Text(
                  'Week Total',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                ),
                const Spacer(),
                Text(
                  '${weekTotal.toStringAsFixed(0)} / ${weekBudget.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isOvershoot
                    ? Colors.red.withValues(alpha: 0.08)
                    : Colors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    isOvershoot ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                    size: 16,
                    color: isOvershoot ? Colors.red : Colors.green,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isOvershoot
                        ? 'Overshoot by ${remaining.abs().toStringAsFixed(0)} cal'
                        : 'Remaining: ${remaining.toStringAsFixed(0)} cal',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isOvershoot ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
