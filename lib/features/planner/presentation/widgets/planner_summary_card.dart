import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eatwise/core/constants/app_colors.dart';
import 'package:eatwise/features/planner/providers/planner_provider.dart';

/// Compact planner summary card for the Dashboard.
class PlannerSummaryCard extends ConsumerWidget {
  const PlannerSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ps = ref.watch(plannerNotifierProvider);
    final tasks = ps.tasks;
    final done = tasks.where((t) => t.isDone && !t.isSectionHeader && t.title.isNotEmpty).length;
    final total = tasks.where((t) => !t.isSectionHeader && t.title.isNotEmpty).length;
    final next = tasks.where((t) => !t.isDone && !t.isSectionHeader && t.title.isNotEmpty).toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/planner'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ps.loading
              ? const SizedBox(height: 40, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(
                    children: [
                      const Icon(Icons.checklist, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      const Text('Daily Planner', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      const Spacer(),
                      if (total > 0)
                        Text('$done/$total', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                    ],
                  ),
                  if (total > 0) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: total > 0 ? done / total : 0,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        color: AppColors.primary,
                        minHeight: 4,
                      ),
                    ),
                    if (next.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Next: ${next.first.title}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ] else ...[
                    const SizedBox(height: 4),
                    Text('Tap to plan your day',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                  ],
                ],
            ),
        ),
      ),
    );
  }
}