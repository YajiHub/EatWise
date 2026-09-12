import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eatwise/features/dashboard/providers/stats_provider.dart';
import 'package:eatwise/features/dashboard/providers/monthly_stats_provider.dart';
import 'package:eatwise/features/dashboard/providers/weekly_chart_provider.dart';
import 'package:eatwise/features/dashboard/presentation/screens/dashboard_screen.dart';

class StatsSummaryCard extends ConsumerStatefulWidget {
  const StatsSummaryCard({super.key});

  @override
  ConsumerState<StatsSummaryCard> createState() => _StatsSummaryCardState();
}

class _StatsSummaryCardState extends ConsumerState<StatsSummaryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    // Only watch the cheap provider when collapsed
    final statsAsync = ref.watch(statsProvider);
    final hasData = statsAsync.valueOrNull != null && statsAsync.valueOrNull!.avgDailyCalories > 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.insights, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text('Statistics', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    if (!_expanded && hasData) ...[
                      const SizedBox(width: 8),
                      Text('${statsAsync.valueOrNull!.avgDailyCalories.toInt()} kcal/day', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ],
                    const Spacer(),
                    Icon(_expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                  ],
                ),
              ),
            ),
            if (_expanded) const _StatsExpandedContent(),
          ],
        ),
      ),
    );
  }
}

class _StatsExpandedContent extends ConsumerWidget {
  const _StatsExpandedContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsProvider);
    final stats = statsAsync.valueOrNull;
    final targetCal = ref.watch(targetCaloriesProvider);
    final monthlyAsync = ref.watch(monthlyStatsProvider);
    final monthly = monthlyAsync.valueOrNull;
    final dates = ref.watch(weekDatesProvider);
    final chartAsync = ref.watch(weeklyChartProvider);
    final summaries = chartAsync.valueOrNull ?? [];

    double weekTotal = 0;
    for (final d in dates) {
      final match = summaries.where((s) => s.date == d).toList();
      weekTotal += match.isNotEmpty ? match.first.totalCalories : 0;
    }
    final weekBudget = targetCal * 7;
    final weekRemaining = weekBudget - weekTotal;
    final weekOvershoot = weekRemaining < 0;

    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final monthBudget = targetCal * daysInMonth;
    final monthRemaining = monthly != null ? (monthBudget - monthly.totalCalories) : 0.0;
    final monthOvershoot = monthRemaining < 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Weekly Budget', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 4),
          _row('Consumed', '${weekTotal.toStringAsFixed(0)} cal'),
          _row('Full Week Budget', '${weekBudget.toStringAsFixed(0)} cal'),
          _statusBadge(weekOvershoot, weekRemaining),
          const Divider(height: 20),

          if (stats != null) ...[
            const Text('Weekly Averages', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 4),
            if (stats.avgDailyCalories == 0)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No data this week', style: TextStyle(color: Colors.grey)),
              )
            else ...[
              _row('Avg Calories', '${stats.avgDailyCalories.toInt()} kcal'),
              _row('Avg Protein', '${stats.avgProtein.toStringAsFixed(1)} g'),
              _row('Avg Carbs', '${stats.avgCarbs.toStringAsFixed(1)} g'),
              _row('Avg Fats', '${stats.avgFats.toStringAsFixed(1)} g'),
              const Divider(height: 16),
              if (stats.bestDay != null)
                _row('Best Day', '${stats.bestDay} (${stats.bestDayCalories.toInt()} cal)'),
              _row('Streak', '${stats.currentStreak} day${stats.currentStreak == 1 ? '' : 's'}'),
            ],
            const Divider(height: 20),
          ],

          const Text('Monthly Budget', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 4),
          if (monthly == null || monthly.loggedDaysCount == 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('No data this month', style: TextStyle(color: Colors.grey)),
            )
          else ...[
            _row('Consumed', '${monthly.totalCalories.toStringAsFixed(0)} cal'),
            _row('Full Month Budget', '${monthBudget.toStringAsFixed(0)} cal'),
            _statusBadge(monthOvershoot, monthRemaining),
            const Divider(height: 16),
            _row('Daily Avg', '${monthly.avgDailyCalories.toStringAsFixed(0)} cal'),
            _row('Logged Days', '${monthly.loggedDaysCount} day${monthly.loggedDaysCount == 1 ? '' : 's'}'),
          ],
        ],
      ),
    );
  }

  static Widget _statusBadge(bool overshoot, double remaining) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: overshoot ? Colors.red.withValues(alpha: 0.08) : Colors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            overshoot ? Icons.warning_amber_rounded : Icons.check_circle_outline,
            size: 16,
            color: overshoot ? Colors.red : Colors.green,
          ),
          const SizedBox(width: 6),
          Text(
            overshoot
                ? 'Overshoot by ${remaining.abs().toStringAsFixed(0)} cal'
                : 'Remaining: ${remaining.toStringAsFixed(0)} cal',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: overshoot ? Colors.red : Colors.green),
          ),
        ],
      ),
    );
  }
}

Widget _row(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    ),
  );
}
