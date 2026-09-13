import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
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
    final offset = ref.watch(hubWeekOffsetProvider);

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

    final firstDt = dates.isNotEmpty ? DateTime.tryParse(dates.first) : null;
    final lastDt = dates.isNotEmpty ? DateTime.tryParse(dates.last) : null;
    final weekLabel = (firstDt != null && lastDt != null)
        ? (offset == 0
            ? 'This Week (${DateFormat('MMM d').format(firstDt)} – ${DateFormat('MMM d').format(lastDt)})'
            : (offset == -1
                ? 'Last Week (${DateFormat('MMM d').format(firstDt)} – ${DateFormat('MMM d').format(lastDt)})'
                : '${DateFormat('MMM d').format(firstDt)} – ${DateFormat('MMM d').format(lastDt)}'))
        : '';
    final hasAnyData = data.any((d) => d.calories > 0);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  const Icon(Icons.bar_chart_rounded, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Weekly Calories',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (weekLabel.isNotEmpty)
                          Text(
                            weekLabel,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 22),
                    tooltip: 'Previous week',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => ref.read(hubWeekOffsetProvider.notifier).state--,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.chevron_right_rounded,
                      size: 22,
                      color: offset >= 0 ? (isDark ? Colors.white24 : Colors.black26) : null,
                    ),
                    tooltip: 'Next week',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: offset >= 0
                        ? null
                        : () => ref.read(hubWeekOffsetProvider.notifier).state++,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: chartAsync.isLoading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        BarChart(
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
                    if (!hasAnyData)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xE6111726) : Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark ? AppColors.surfaceCardBorder : Colors.grey.shade300,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_today_outlined, size: 14, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                              const SizedBox(width: 8),
                              Text(
                                'No meals logged this week',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                ),
                              ),
                            ],
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
