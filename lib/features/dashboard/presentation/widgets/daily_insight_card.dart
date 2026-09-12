import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:eatwise/core/constants/app_colors.dart';
import 'package:eatwise/features/dashboard/presentation/providers/daily_insight_provider.dart';

class DailyInsightCard extends ConsumerWidget {
  final RemainingMacros remaining;

  const DailyInsightCard({super.key, required this.remaining});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightAsync = ref.watch(dailyInsightProvider(remaining));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.07),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lightbulb_outline, size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Text(
                  'Daily Insight',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => ref.invalidate(dailyInsightProvider(remaining)),
                  child: Icon(Icons.refresh, size: 18, color: AppColors.primary.withValues(alpha: 0.7)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            insightAsync.when(
              loading: () => _ShimmerLines(isDark: isDark),
              error: (_, __) => const Text(
                'A balanced snack like Greek yogurt or a handful of nuts always works.',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
              data: (text) => Text(
                text,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerLines extends StatelessWidget {
  final bool isDark;
  const _ShimmerLines({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final base = isDark ? Colors.white12 : Colors.grey.shade300;
    final highlight = isDark ? Colors.white24 : Colors.grey.shade100;
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _line(0.9),
          const SizedBox(height: 8),
          _line(0.75),
          const SizedBox(height: 8),
          _line(0.6),
        ],
      ),
    );
  }

  Widget _line(double widthFactor) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: 12,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}
