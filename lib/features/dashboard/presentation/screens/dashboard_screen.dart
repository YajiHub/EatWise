import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:eatwise/core/database/app_database.dart';
import 'package:eatwise/core/constants/app_colors.dart';
import 'package:eatwise/core/theme/theme_mode_provider.dart';
import 'package:eatwise/features/dashboard/providers/profile_provider.dart';
import 'package:eatwise/features/dashboard/presentation/widgets/athletic_hero_dial.dart';
import 'package:eatwise/features/dashboard/presentation/widgets/macro_pill_trio.dart';
import 'package:eatwise/features/dashboard/presentation/widgets/todays_fuel_section.dart';
import 'package:eatwise/features/dashboard/presentation/widgets/daily_insight_card.dart';
import 'package:eatwise/features/dashboard/presentation/providers/daily_insight_provider.dart';
import 'package:eatwise/features/dashboard/presentation/widgets/weight_card.dart';
import 'package:eatwise/features/dashboard/presentation/widgets/weekly_calorie_chart.dart';
import 'package:eatwise/features/dashboard/presentation/widgets/fasting_timer_widget.dart';
import 'package:eatwise/features/planner/presentation/widgets/planner_summary_card.dart';
import 'package:eatwise/features/dashboard/providers/dashboard_providers.dart';
import 'package:eatwise/features/dashboard/providers/stats_provider.dart';
export 'package:eatwise/features/dashboard/providers/dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(today);
    final totalsAsync = ref.watch(dailyTotalsProvider(dateStr));
    final consumed = totalsAsync.valueOrNull?['calories'] ?? 0.0;
    final protein = totalsAsync.valueOrNull?['protein'] ?? 0.0;
    final carbs = totalsAsync.valueOrNull?['carbs'] ?? 0.0;
    final fats = totalsAsync.valueOrNull?['fats'] ?? 0.0;
    final target = ref.watch(targetCaloriesProvider);
    final targetProtein = ref.watch(targetProteinProvider);
    final targetCarbs = ref.watch(targetCarbsProvider);
    final targetFats = ref.watch(targetFatsProvider);

    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    final profile = ref.watch(profileProvider);
    final userName = profile.name.isNotEmpty
        ? profile.name
        : (ref.watch(userNameProvider).valueOrNull ?? '');
    final avatarUrl = profile.avatarUrl;
    final statsAsync = ref.watch(statsProvider);
    final streak = statsAsync.valueOrNull?.currentStreak ?? 0;
    final showFasting = ref.watch(showFastingOnHubProvider);

    return Scaffold(
      extendBody: true,
      floatingActionButton: FloatingActionButton(
        tooltip: 'Log a meal',
        onPressed: () => context.go('/chat-log'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        elevation: 6,
        child: const Icon(Icons.edit_note_rounded, size: 28),
      ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(116),
        child: _HomeHeader(
          userName: userName,
          avatarUrl: avatarUrl,
          isDark: isDark,
          streak: streak,
          onToggleTheme: () => ref.read(themeModeProvider.notifier).toggle(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 96),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 6),

            // ── Hero Concentric Dial (Calorie Budget + Fasting Ring) ──
            AthleticHeroDialCard(
              consumed: consumed,
              target: target,
              fastingLabel: '16:8 Fasting • Active',
              onTap: () => _editCalorieTarget(context, ref),
            ),

            const SizedBox(height: 8),

            // ── Athletic 3-Pill Macro Telemetry Row (Protein, Carbs, Fats) ──
            MacroBreakdownPillTrio(
              proteinConsumed: protein,
              proteinTarget: targetProtein,
              carbsConsumed: carbs,
              carbsTarget: targetCarbs,
              fatsConsumed: fats,
              fatsTarget: targetFats,
            ),

            const SizedBox(height: 10),

            // ── Fast AI Log Action Button ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.go('/chat-log'),
                  borderRadius: BorderRadius.circular(14),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, Color(0xFF00C853)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.28),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome_rounded, color: Colors.black, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Log Meal with AI Coach',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Today's Fuel Section (Logged Meals Timeline) ──
            TodaysFuelSection(dateStr: dateStr),

            const SizedBox(height: 10),

            // ── Daily Nutrition Insight Card ──
            DailyInsightCard(
              remaining: RemainingMacros(
                calories: target - consumed,
                protein: targetProtein - protein,
                carbs: targetCarbs - carbs,
                fats: targetFats - fats,
                consumedCalories: consumed,
              ),
            ),

            const SizedBox(height: 12),

            // ── Weekly Calorie Bar Chart ──
            WeeklyCalorieBarChart(targetCalories: target),

            const SizedBox(height: 12),

            // ── Fasting Schedule (Hub Integration) ──
            if (showFasting) ...[
              const FastingTimerWidget(),
              const SizedBox(height: 12),
            ],

            // ── Meal Planner Summary ──
            const PlannerSummaryCard(),

            const SizedBox(height: 12),

            // ── Weight Tracking Card ──
            const WeightCard(),
            const SizedBox(height: 16),
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

class _HomeHeader extends StatelessWidget {
  final String userName;
  final String? avatarUrl;
  final bool isDark;
  final int streak;
  final VoidCallback onToggleTheme;

  const _HomeHeader({
    required this.userName,
    this.avatarUrl,
    required this.isDark,
    required this.streak,
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
    final nameLine = userName.isNotEmpty ? userName : 'Athlete';
    final dateFormatted = DateFormat('EEE, MMM d').format(DateTime.now());

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row 1: Brand & Actions
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'EatWise',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: AppColors.carbs.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(
                      color: AppColors.carbs.withValues(alpha: 0.35),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    '🔥 ${streak}d streak',
                    style: const TextStyle(
                      color: AppColors.carbs,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: Icon(
                    isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                    size: 20,
                    color: isDark ? AppColors.textSecondaryDark : Colors.black54,
                  ),
                  tooltip: isDark ? 'Light mode' : 'Dark mode',
                  onPressed: onToggleTheme,
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => context.push('/profile'),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 17,
                      backgroundColor: isDark
                          ? AppColors.surfaceContainerHigh
                          : AppColors.primary.withValues(alpha: 0.15),
                      backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                          ? (avatarUrl!.startsWith('http')
                              ? NetworkImage(avatarUrl!)
                              : FileImage(File(avatarUrl!))) as ImageProvider
                          : null,
                      child: avatarUrl == null || avatarUrl!.isEmpty
                          ? Text(
                              initials,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 11.5,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Row 2: Greeting & Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DAILY OVERVIEW',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$greeting, $nameLine',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF141923) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? const Color(0x18FFFFFF) : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    dateFormatted,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

