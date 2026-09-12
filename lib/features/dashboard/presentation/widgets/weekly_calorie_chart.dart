import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:eatwise/features/dashboard/providers/weekly_chart_provider.dart';
import 'package:eatwise/core/constants/app_colors.dart';

class WeeklyCalorieBarChart extends ConsumerWidget {
  final double targetCalories;

  const WeeklyCalorieBarChart({super.key, required this.targetCalories});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartAsync = ref.watch(weeklyChartProvider);
    final summaries = chartAsync.valueOrNull ?? [];
    final dates = ref.watch(weekDatesProvider);

    final data = <_DayBar>[];
    for (final d in dates) {
      final match = summaries.where((s) => s.date == d).toList();
      data.add(_DayBar(
        label: _shortDay(d),
        calories: match.isNotEmpty ? match.first.totalCalories : 0,
        protein: match.isNotEmpty ? match.first.totalProtein : 0,
        carbs: match.isNotEmpty ? match.first.totalCarbs : 0,
        fats: match.isNotEmpty ? match.first.totalFats : 0,
      ));
    }

    final maxY = [targetCalories * 1.2, ...data.map((d) => d.calories)].reduce((a, b) => a > b ? a : b);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final now = DateTime.now();
    final loggedVals = <double>[];
    for (var i = 0; i < dates.length; i++) {
      final dt = DateTime.tryParse(dates[i]);
      if (dt != null && !dt.isAfter(now)) loggedVals.add(data[i].calories);
    }
    final avg = loggedVals.isEmpty
        ? 0.0
        : loggedVals.reduce((a, b) => a + b) / loggedVals.length;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Row(
                children: [
                  const Icon(Icons.bar_chart, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text('Weekly Calories', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: chartAsync.isLoading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                  : BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxY,
                        extraLinesData: ExtraLinesData(
                          horizontalLines: [
                            if (avg > 0)
                              HorizontalLine(
                                y: avg,
                                color: AppColors.secondary.withValues(alpha: 0.6),
                                strokeWidth: 1.5,
                                dashArray: [5, 5],
                                label: HorizontalLineLabel(
                                  show: true,
                                  alignment: Alignment.topRight,
                                  padding: const EdgeInsets.only(right: 8),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  labelResolver: (_) =>
                                      'avg ${avg.toStringAsFixed(0)}',
                                ),
                              ),
                          ],
                        ),
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final d = data[groupIndex];
                              return BarTooltipItem(
                                '${d.calories.toInt()} cal\nP:${d.protein.toInt()} C:${d.carbs.toInt()} F:${d.fats.toInt()}g',
                                TextStyle(color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.w600),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final i = value.toInt();
                                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(data[i].label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                );
                              },
                            ),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: targetCalories,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(color: Colors.orange.withValues(alpha: 0.3), strokeWidth: 1, dashArray: [5, 5]);
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(
                          data.length,
                          (i) => BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: data[i].calories,
                                color: data[i].calories <= targetCalories ? AppColors.primary : AppColors.protein,
                                width: 22,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _shortDay(String dateStr) {
    final d = DateTime.tryParse(dateStr);
    if (d == null) return '';
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return days[d.weekday - 1];
  }
}

class _DayBar {
  final String label;
  final double calories;
  final double protein;
  final double carbs;
  final double fats;

  const _DayBar({
    required this.label,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
  });
}
