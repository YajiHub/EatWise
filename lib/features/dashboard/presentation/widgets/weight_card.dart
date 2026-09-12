import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:eatwise/core/constants/app_colors.dart';
import 'package:eatwise/core/database/app_database.dart';
import 'package:eatwise/features/dashboard/models/weight_entry.dart';
import 'package:eatwise/features/dashboard/presentation/widgets/weight_entry_sheet.dart';
import 'package:eatwise/features/dashboard/providers/weight_provider.dart';

class WeightCard extends ConsumerWidget {
  const WeightCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weightAsync = ref.watch(latestWeightProvider);
    final previousAsync = ref.watch(previousWeightProvider);
    final heightAsync = ref.watch(heightCmProvider);
    final goalAsync = ref.watch(goalWeightProvider);
    final entriesAsync = ref.watch(weightEntriesProvider);

    final weight = weightAsync.valueOrNull;
    final previous = previousAsync.valueOrNull;
    final heightCm = heightAsync.valueOrNull;
    final goalKg = goalAsync.valueOrNull;
    final entries = entriesAsync.valueOrNull;
    final startKg =
        (entries != null && entries.isNotEmpty) ? entries.last.weightKg : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/weight-history'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.scale, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text('Weight', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (_) => const WeightEntrySheet(),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.add, size: 18, color: Theme.of(context).colorScheme.onPrimaryContainer),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
                ],
              ),
              const SizedBox(height: 12),
              if (weight == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Tap to log your weight', style: TextStyle(color: Colors.grey, fontSize: 15)),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${weight.weightKg.toStringAsFixed(1)} kg',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 16),
                        if (heightCm != null && heightCm > 0) _bmiChip(weight.weightKg, heightCm),
                        const Spacer(),
                        if (previous != null) _deltaChip(weight.weightKg, previous.weightKg),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _WeightTrend(entries: entries ?? const [], goalKg: goalKg),
                    const SizedBox(height: 10),
                    _GoalProgress(
                      currentKg: weight.weightKg,
                      startKg: startKg,
                      goalKg: goalKg,
                      onEditGoal: () => _editGoal(context, ref),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bmiChip(double weightKg, double heightCm) {
    final heightM = heightCm / 100;
    final bmi = weightKg / (heightM * heightM);
    Color color;
    if (bmi < 18.5) {
      color = Colors.blue;
    } else if (bmi < 25) {
      color = Colors.green;
    } else if (bmi < 30) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('BMI ${bmi.toStringAsFixed(1)}', style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }

  Widget _deltaChip(double current, double previous) {
    final delta = current - previous;
    final isDown = delta <= 0;
    final color = isDown ? Colors.green : Colors.red;
    final arrow = isDown ? '↓' : '↑';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$arrow ${delta.abs().toStringAsFixed(1)} kg',
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }

  void _editGoal(BuildContext context, WidgetRef ref) {
    final currentGoal = ref.read(goalWeightProvider).valueOrNull;
    final controller = TextEditingController(
      text: currentGoal != null ? currentGoal.toStringAsFixed(1) : '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Weight Goal'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          decoration: const InputDecoration(
            labelText: 'Target weight',
            suffixText: 'kg',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val > 0) {
                AppDatabase.setSetting('goal_weight_kg', val.toStringAsFixed(1));
                ref.invalidate(goalWeightProvider);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _GoalProgress extends StatelessWidget {
  final double currentKg;
  final double? startKg;
  final double? goalKg;
  final VoidCallback onEditGoal;

  const _GoalProgress({
    required this.currentKg,
    required this.startKg,
    required this.goalKg,
    required this.onEditGoal,
  });

  @override
  Widget build(BuildContext context) {
    if (goalKg == null || goalKg! <= 0) {
      return GestureDetector(
        onTap: onEditGoal,
        child: Row(
          children: [
            const Icon(Icons.flag_outlined, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            const Text('Set a weight goal',
                style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
          ],
        ),
      );
    }

    final goal = goalKg!;
    final distance = (currentKg - goal).abs();
    final atGoal = distance < 0.1;

    double progress = 0;
    if (startKg != null && (startKg! - goal).abs() >= 0.05) {
      final start = startKg!;
      if (goal < start) {
        progress = ((start - currentKg) / (start - goal)).clamp(0.0, 1.0);
      } else {
        progress = ((currentKg - start) / (goal - start)).clamp(0.0, 1.0);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.flag_outlined, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onEditGoal,
              child: Text(
                'Goal: ${goal.toStringAsFixed(1)} kg',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary),
              ),
            ),
            const Spacer(),
            Text(
              atGoal ? 'At goal!' : '${distance.toStringAsFixed(1)} kg to go',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: atGoal ? AppColors.primary : Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            color: AppColors.primary,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          ),
        ),
      ],
    );
  }
}

class _WeightTrend extends StatelessWidget {
  final List<WeightEntry> entries; // newest first
  final double? goalKg;

  const _WeightTrend({required this.entries, required this.goalKg});

  @override
  Widget build(BuildContext context) {
    if (entries.length < 2) return const SizedBox.shrink();

    final ordered = entries.reversed.toList(); // oldest first
    final spots = <FlSpot>[];
    for (var i = 0; i < ordered.length; i++) {
      spots.add(FlSpot(i.toDouble(), ordered[i].weightKg));
    }
    final weights = ordered.map((e) => e.weightKg).toList();
    var minY = weights.fold(double.infinity, (a, b) => a < b ? a : b);
    var maxY = weights.fold(-double.infinity, (a, b) => a > b ? a : b);
    if (goalKg != null) {
      if (goalKg! < minY) minY = goalKg!;
      if (goalKg! > maxY) maxY = goalKg!;
    }
    final pad = ((maxY - minY) * 0.2).clamp(0.5, 3.0);
    minY -= pad;
    maxY += pad;

    return SizedBox(
      height: 72,
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          minX: 0,
          maxX: (ordered.length - 1).toDouble(),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.primary,
              barWidth: 2.5,
              dotData: FlDotData(show: ordered.length <= 8),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withValues(alpha: 0.12),
              ),
            ),
          ],
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              if (goalKg != null)
                HorizontalLine(
                  y: goalKg!,
                  color: AppColors.primary.withValues(alpha: 0.4),
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
