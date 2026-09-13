import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eatwise/core/constants/app_colors.dart';
import 'package:eatwise/core/database/app_database.dart';
import 'package:eatwise/features/dashboard/providers/dashboard_providers.dart';

/// Athletic 3-Pill Macro Telemetry Row (Protein, Carbs, Fats)
/// Matching Figma node 1:404 and Stitch Obsidian specifications.
class MacroBreakdownPillTrio extends ConsumerWidget {
  final double proteinConsumed;
  final double proteinTarget;
  final double carbsConsumed;
  final double carbsTarget;
  final double fatsConsumed;
  final double fatsTarget;

  const MacroBreakdownPillTrio({
    super.key,
    required this.proteinConsumed,
    required this.proteinTarget,
    required this.carbsConsumed,
    required this.carbsTarget,
    required this.fatsConsumed,
    required this.fatsTarget,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: _MacroCard(
              label: 'PROTEIN',
              consumed: proteinConsumed,
              target: proteinTarget,
              color: AppColors.protein,
              badgeColor: AppColors.proteinLight,
              onTap: () => _editTarget(
                context,
                ref,
                'Protein',
                proteinTarget,
                targetProteinProvider,
                'target_protein',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _MacroCard(
              label: 'CARBS',
              consumed: carbsConsumed,
              target: carbsTarget,
              color: AppColors.carbs,
              badgeColor: AppColors.carbsLight,
              onTap: () => _editTarget(
                context,
                ref,
                'Carbs',
                carbsTarget,
                targetCarbsProvider,
                'target_carbs',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _MacroCard(
              label: 'FATS',
              consumed: fatsConsumed,
              target: fatsTarget,
              color: AppColors.fats,
              badgeColor: AppColors.primaryLight,
              onTap: () => _editTarget(
                context,
                ref,
                'Fats',
                fatsTarget,
                targetFatsProvider,
                'target_fats',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editTarget(
    BuildContext context,
    WidgetRef ref,
    String label,
    double currentTarget,
    StateProvider<double> provider,
    String dbKey,
  ) {
    final controller =
        TextEditingController(text: currentTarget.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('$label Daily Target'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'Grams per day',
            suffixText: 'g',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimaryDark,
            ),
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val > 0) {
                ref.read(provider.notifier).state = val;
                AppDatabase.setSetting(dbKey, val.toStringAsFixed(1));
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

class _MacroCard extends StatelessWidget {
  final String label;
  final double consumed;
  final double target;
  final Color color;
  final Color badgeColor;
  final VoidCallback onTap;

  const _MacroCard({
    required this.label,
    required this.consumed,
    required this.target,
    required this.color,
    required this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ratio = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;
    final percentage = (ratio * 100).round();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.surfaceCardBorder : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Macro Label + Percentage
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : Colors.grey.shade600,
                  ),
                ),
                Text(
                  '$percentage%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Readout: Consumed / Target
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    consumed.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    ' / ${target.toStringAsFixed(0)}g',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Progress Line
            ClipRRect(
              borderRadius: BorderRadius.circular(9999),
              child: Container(
                height: 6,
                color: isDark
                    ? AppColors.surfaceContainerHighest
                    : Colors.grey.shade200,
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: ratio,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(9999),
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
}
