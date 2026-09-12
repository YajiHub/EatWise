import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:eatwise/core/constants/app_colors.dart';

/// A ring chart showing progress for calories or a macro
class MacroRingChart extends ConsumerWidget {
  final double consumed;
  final double target;
  final Color progressColor;
  final Color bgColor;
  final String label;
  final String unit;
  final double size;
  final double strokeWidth;

  const MacroRingChart({
    super.key,
    required this.consumed,
    required this.target,
    required this.progressColor,
    required this.bgColor,
    required this.label,
    required this.unit,
    this.size = 100,
    this.strokeWidth = 10,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ratio = target > 0 ? (consumed / target).clamp(0.0, 1.2) : 0.0;
    final remaining = target - consumed;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subtitleColor = isDark ? Colors.white54 : Colors.grey.shade600;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              startDegreeOffset: 270,
              sectionsSpace: 0,
              centerSpaceRadius: size / 2 - strokeWidth,
              sections: [
                PieChartSectionData(
                  value: ratio.clamp(0.0, 1.0) * 100,
                  color: progressColor,
                  showTitle: false,
                  radius: strokeWidth,
                ),
                PieChartSectionData(
                  value: ((1.0 - ratio).clamp(0.0, 1.0)) * 100,
                  color: bgColor,
                  showTitle: false,
                  radius: strokeWidth - 2,
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: size * 0.12,
                  fontWeight: FontWeight.w600,
                  color: subtitleColor,
                ),
              ),
              Text(
                '${consumed.toStringAsFixed(0)}/${target.toStringAsFixed(0)}$unit',
                style: TextStyle(
                  fontSize: size * 0.16,
                  fontWeight: FontWeight.bold,
                  color: ratio >= 1.0 ? AppColors.protein : textColor,
                ),
              ),
              Text(
                remaining >= 0 ? '${remaining.toStringAsFixed(0)}$unit left' : '${(-remaining).toStringAsFixed(0)}$unit over',
                style: TextStyle(
                  fontSize: size * 0.1,
                  color: subtitleColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Three horizontal macro rings for protein, carbs, fats
class MacroRingsRow extends ConsumerWidget {
  final double proteinConsumed;
  final double proteinTarget;
  final double carbsConsumed;
  final double carbsTarget;
  final double fatsConsumed;
  final double fatsTarget;
  final double size;

  const MacroRingsRow({
    super.key,
    required this.proteinConsumed,
    required this.proteinTarget,
    required this.carbsConsumed,
    required this.carbsTarget,
    required this.fatsConsumed,
    required this.fatsTarget,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.white12 : Colors.grey.shade200;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        MacroRingChart(
          consumed: proteinConsumed,
          target: proteinTarget,
          progressColor: AppColors.protein,
          bgColor: bgColor,
          label: 'Protein',
          unit: 'g',
          size: size,
        ),
        MacroRingChart(
          consumed: carbsConsumed,
          target: carbsTarget,
          progressColor: AppColors.carbs,
          bgColor: bgColor,
          label: 'Carbs',
          unit: 'g',
          size: size,
        ),
        MacroRingChart(
          consumed: fatsConsumed,
          target: fatsTarget,
          progressColor: AppColors.fats,
          bgColor: bgColor,
          label: 'Fats',
          unit: 'g',
          size: size,
        ),
      ],
    );
  }
}

/// Original calorie ring chart (kept for backward compatibility)
class CalorieRingChart extends ConsumerWidget {
  final double consumed;
  final double target;

  const CalorieRingChart({
    super.key,
    required this.consumed,
    required this.target,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ratio = target > 0 ? (consumed / target).clamp(0.0, 1.2) : 0.0;
    final remaining = target - consumed;

    final ringColor = ratio >= 1.0
        ? AppColors.protein
        : ratio >= 0.75
            ? AppColors.primary
            : AppColors.secondaryLight;

    final bgColor = isDark ? Colors.white12 : Colors.grey.shade200;

    // Text always readable — dark on light, light on dark
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subtitleColor = isDark ? Colors.white54 : Colors.grey.shade600;

    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              startDegreeOffset: 270,
              sectionsSpace: 2,
              centerSpaceRadius: 72,
              sections: [
                PieChartSectionData(
                  value: ratio.clamp(0.0, 1.0).toDouble() * 100,
                  color: ringColor,
                  showTitle: false,
                  radius: 18,
                ),
                PieChartSectionData(
                  value: ((1.0 - ratio).clamp(0.0, 1.0) * 100).toDouble(),
                  color: bgColor,
                  showTitle: false,
                  radius: 14,
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                (remaining >= 0 ? remaining : -remaining).toStringAsFixed(0),
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: ratio >= 1.0 ? AppColors.protein : textColor,
                ),
              ),
              Text(
                remaining >= 0 ? 'calories left' : 'calories over',
                style: TextStyle(
                  fontSize: 14,
                  color: subtitleColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${consumed.toStringAsFixed(0)} / ${target.toStringAsFixed(0)} cal',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: subtitleColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
