import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:eatwise/core/database/app_database.dart';
import 'package:eatwise/features/dashboard/presentation/widgets/calorie_ring_chart.dart';
import 'package:eatwise/features/dashboard/presentation/widgets/daily_insight_card.dart';
import 'package:eatwise/features/dashboard/presentation/providers/daily_insight_provider.dart';
import 'package:eatwise/features/dashboard/presentation/widgets/weight_card.dart';
import 'package:eatwise/features/dashboard/presentation/widgets/weekly_calorie_chart.dart';
import 'package:eatwise/core/constants/app_colors.dart';
import 'package:eatwise/features/dashboard/presentation/widgets/fasting_timer_widget.dart';
import 'package:eatwise/core/theme/theme_mode_provider.dart';
import 'package:eatwise/features/planner/presentation/widgets/planner_summary_card.dart';
import 'package:eatwise/features/dashboard/providers/dashboard_providers.dart';
export 'package:eatwise/features/dashboard/providers/dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    final totalsAsync = ref.watch(dailyTotalsProvider(dateStr));
    final consumed = totalsAsync.valueOrNull?['calories'] ?? 0;
    final protein = totalsAsync.valueOrNull?['protein'] ?? 0;
    final carbs = totalsAsync.valueOrNull?['carbs'] ?? 0;
    final fats = totalsAsync.valueOrNull?['fats'] ?? 0;
    final target = ref.watch(targetCaloriesProvider);
    final targetProtein = ref.watch(targetProteinProvider);
    final targetCarbs = ref.watch(targetCarbsProvider);
    final targetFats = ref.watch(targetFatsProvider);

    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return Scaffold(
      extendBody: true,
      floatingActionButton: FloatingActionButton(
        tooltip: 'Log a meal',
        onPressed: () => context.go('/chat-log'),
        child: const Icon(Icons.edit_note_rounded),
      ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: _HomeHeader(
          userName: ref.watch(userNameProvider).valueOrNull ?? '',
          isDark: isDark,
          onToggleTheme: () => ref.read(themeModeProvider.notifier).toggle(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),

            // ── Macro Ring (tap to edit calorie target) ──
            Center(
              child: GestureDetector(
                onTap: () => _editCalorieTarget(context, ref),
                child: CalorieRingChart(consumed: consumed, target: target),
              ),
            ),

            // ── Macro Rings ──
            const SizedBox(height: 16),
            MacroRingsRow(
              proteinConsumed: protein,
              proteinTarget: targetProtein,
              carbsConsumed: carbs,
              carbsTarget: targetCarbs,
              fatsConsumed: fats,
              fatsTarget: targetFats,
              size: 90,
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _EditableMacroChip(
                      label: 'Protein',
                      consumed: protein,
                      target: targetProtein,
                      color: AppColors.protein,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _EditableMacroChip(
                      label: 'Carbs',
                      consumed: carbs,
                      target: targetCarbs,
                      color: AppColors.carbs,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _EditableMacroChip(
                      label: 'Fats',
                      consumed: fats,
                      target: targetFats,
                      color: AppColors.fats,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: FilledButton.icon(
                onPressed: () => context.go('/chat-log'),
                icon: const Icon(Icons.auto_awesome_outlined),
                label: const Text('Log a meal with AI'),
              ),
            ),

            DailyInsightCard(
              remaining: RemainingMacros(
                calories: target - consumed,
                protein: targetProtein - protein,
                carbs: targetCarbs - carbs,
                fats: targetFats - fats,
              ),
            ),
            const SizedBox(height: 8),

            WeeklyCalorieBarChart(targetCalories: target),
            const SizedBox(height: 8),

            if (ref.watch(fastingEnabledProvider).valueOrNull == true) ...[
              const FastingTimerWidget(),
              const SizedBox(height: 8),
            ],

            const PlannerSummaryCard(),
            const SizedBox(height: 8),
            const WeightCard(),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  void _editCalorieTarget(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(
      text: ref.read(targetCaloriesProvider).toStringAsFixed(0),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Daily Calorie Target'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Calories per day',
            suffixText: 'cal',
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
                ref.read(targetCaloriesProvider.notifier).state = val;
                AppDatabase.setSetting('target_calories', val.toStringAsFixed(0));
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

class _EditableMacroChip extends ConsumerWidget {
  final String label;
  final double consumed;
  final double target;
  final Color color;

  const _EditableMacroChip({
    required this.label,
    required this.consumed,
    required this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratio = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;

    return GestureDetector(
      onTap: () => _editTarget(context, ref),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${consumed.toStringAsFixed(0)}g',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              Text(
                'of ${target.toStringAsFixed(0)}g',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 6,
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editTarget(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: target.toStringAsFixed(0));
    final provider = label == 'Protein'
        ? targetProteinProvider
        : label == 'Carbs'
            ? targetCarbsProvider
            : targetFatsProvider;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$label Target'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: '$label per day',
            suffixText: 'g',
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
                ref.read(provider.notifier).state = val;
                final key = label == 'Protein' ? 'target_protein' : label == 'Carbs' ? 'target_carbs' : 'target_fats';
                AppDatabase.setSetting(key, val.toStringAsFixed(1));
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

class _HomeHeader extends StatelessWidget {
  final String userName;
  final bool isDark;
  final VoidCallback onToggleTheme;

  const _HomeHeader({
    required this.userName,
    required this.isDark,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting =
        hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    final initials = (userName.isNotEmpty ? userName : 'EatWise')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0])
        .join()
        .toUpperCase();
    final nameLine = userName.isNotEmpty ? userName : 'Welcome back';

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => context.go('/profile'),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: Text(initials,
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(greeting,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                Text(nameLine,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700)),
              ],
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Settings',
              onPressed: () => context.push('/settings'),
            ),
            IconButton(
              icon: Icon(isDark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined),
              tooltip: isDark ? 'Switch to Light' : 'Switch to Dark',
              onPressed: onToggleTheme,
            ),
          ],
        ),
      ),
    );
  }
}
