import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eatwise/core/constants/app_colors.dart';
import 'package:eatwise/features/dashboard/providers/profile_provider.dart';
import 'package:eatwise/features/dashboard/providers/dashboard_providers.dart';
import 'package:eatwise/features/dashboard/presentation/widgets/fasting_timer_widget.dart';
import 'package:eatwise/features/dashboard/providers/weekly_chart_provider.dart';
import 'package:intl/intl.dart';

class FastingScreen extends ConsumerStatefulWidget {
  const FastingScreen({super.key});

  @override
  ConsumerState<FastingScreen> createState() => _FastingScreenState();
}

class _FastingScreenState extends ConsumerState<FastingScreen>
    with WidgetsBindingObserver {
  DateTime _now = DateTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTimer();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _now = DateTime.now();
      _startTimer();
    } else {
      _stopTimer();
    }
  }

  void _startTimer() {
    _stopTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Widget build(BuildContext context) {
    final now = _now;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = ref.watch(profileProvider);

    final eatUntilTime = ref.watch(fastingStartTimeProvider);
    final eatFromTime = ref.watch(fastingEndTimeProvider);

    final eatUntilMin = eatUntilTime.hour * 60 + eatUntilTime.minute;
    final eatFromMin = eatFromTime.hour * 60 + eatFromTime.minute;

    final int eatingMin;
    if (eatUntilMin >= eatFromMin) {
      eatingMin = eatUntilMin - eatFromMin;
    } else {
      eatingMin = (1440 - eatFromMin) + eatUntilMin;
    }
    final fastingMin = 1440 - eatingMin;
    final scheduleLabel = '${fastingMin ~/ 60}:${eatingMin ~/ 60} PROTOCOL';

    final nowMin = now.hour * 60 + now.minute;

    final bool isEating;
    if (eatUntilMin >= eatFromMin) {
      isEating = nowMin >= eatFromMin && nowMin < eatUntilMin;
    } else {
      isEating = nowMin >= eatFromMin || nowMin < eatUntilMin;
    }

    final int phaseDurationMin = isEating ? eatingMin : fastingMin;
    final int phaseStartMin = isEating ? eatFromMin : eatUntilMin;

    int elapsedMin;
    if (nowMin >= phaseStartMin) {
      elapsedMin = nowMin - phaseStartMin;
    } else {
      elapsedMin = (1440 - phaseStartMin) + nowMin;
    }
    elapsedMin = elapsedMin.clamp(0, phaseDurationMin).toInt();

    final remainingMin = phaseDurationMin - elapsedMin;
    final progress = phaseDurationMin > 0 ? (elapsedMin / phaseDurationMin).clamp(0.0, 1.0) : 0.0;

    final elapsedHours = elapsedMin ~/ 60;
    final elapsedMinutes = elapsedMin % 60;
    final remainingHours = remainingMin ~/ 60;
    final remainingMinutes = remainingMin % 60;

    // Real weekly calorie telemetry from SQLite database
    final chartAsync = ref.watch(weeklyChartProvider);
    final summaries = chartAsync.valueOrNull ?? [];
    final dates = ref.watch(weekDatesProvider);
    final targetCalories = ref.watch(targetCaloriesProvider);

    final dayCals = <double>[];
    for (final d in dates) {
      final match = summaries.where((s) => s.date == d).toList();
      dayCals.add(match.isNotEmpty ? match.first.totalCalories : 0.0);
    }

    final loggedList = <double>[];
    for (var i = 0; i < dates.length; i++) {
      final dt = DateTime.tryParse(dates[i]);
      if (dt != null && !dt.isAfter(DateTime.now()) && dayCals[i] > 0) {
        loggedList.add(dayCals[i]);
      }
    }
    final avgCal = loggedList.isNotEmpty
        ? loggedList.reduce((a, b) => a + b) / loggedList.length
        : 0.0;
    final diff = avgCal > 0 ? (avgCal - targetCalories).round() : 0;

    return Scaffold(
      backgroundColor: isDark ? AppColors.canvasDark : const Color(0xFFF9FAFB),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.timer_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Fasting & Analytics',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const Text(
                      'EATWISE BIO-TRACKER',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.carbs.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(
                      color: AppColors.carbs.withValues(alpha: 0.35),
                      width: 0.8,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '🔥 14d Streak',
                        style: TextStyle(
                          color: AppColors.carbs,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
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
                      backgroundImage: profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                          ? (profile.avatarUrl!.startsWith('http')
                              ? NetworkImage(profile.avatarUrl!)
                              : FileImage(File(profile.avatarUrl!))) as ImageProvider
                          : null,
                      child: profile.avatarUrl == null || profile.avatarUrl!.isEmpty
                          ? Text(
                              (profile.name.isNotEmpty ? profile.name[0] : 'E').toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Card 1: Fasting Telemetry & Circadian Dial ──
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceCard : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark ? AppColors.surfaceCardBorder : Colors.grey.shade200,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Top Tags
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.nights_stay_rounded,
                            size: 14,
                            color: AppColors.fasting,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'METABOLIC WINDOW',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(9999),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          scheduleLabel,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Heading
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fasting Telemetry',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Circadian rhythm and cellular recovery tracking',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Concentric Circular Ring Dial ──
                  SizedBox(
                    height: 220,
                    width: 220,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(220, 220),
                          painter: _FastingRingPainter(
                            progress: progress,
                            isEating: isEating,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: (isEating ? AppColors.eating : AppColors.primary).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: isEating ? AppColors.eating : AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    isEating
                                        ? 'EATING ACTIVE'
                                        : (elapsedHours >= 14 ? 'IN KETOSIS' : 'FASTING ACTIVE'),
                                    style: TextStyle(
                                      color: isEating ? AppColors.eating : AppColors.primary,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${elapsedHours}h ${elapsedMinutes}m',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              isEating ? 'EATING TIME' : 'FASTING TIME',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                                color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isEating
                                  ? '${remainingHours}h ${remainingMinutes}m to fast window'
                                  : '${remainingHours}h ${remainingMinutes}m to 16h goal (${eatFromTime.format(context)})',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Legend
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _legendDot(AppColors.primary, 'FASTING (${eatUntilTime.format(context)} - ${eatFromTime.format(context)})', isDark),
                      const SizedBox(width: 16),
                      _legendDot(AppColors.eating, 'EATING (${eatFromTime.format(context)} - ${eatUntilTime.format(context)})', isDark),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Card 2: Weekly Caloric Trend & Adherence ──
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceCard : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark ? AppColors.surfaceCardBorder : Colors.grey.shade200,
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WEEKLY CALORIC TREND',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                              color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Daily Calorie Load',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.trending_up, size: 13, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              'TARGET: ${targetCalories.toStringAsFixed(0)} KCAL',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Real 7-day bar chart from SQLite
                  _buildCalorieBarChart(
                    dayCals: dayCals,
                    dates: dates,
                    targetCalories: targetCalories,
                    isDark: isDark,
                  ),

                  const SizedBox(height: 20),
                  const Divider(height: 1, color: Color(0x14FFFFFF)),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AVG DAILY INTAKE',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                                color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            RichText(
                              text: TextSpan(
                                text: avgCal > 0 ? '${avgCal.toStringAsFixed(0)} ' : '0 ',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'kcal',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              avgCal <= 0
                                  ? 'No meals logged this week'
                                  : (diff < 0
                                      ? '${diff.abs()} kcal deficit (Optimal)'
                                      : '$diff kcal surplus'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: diff <= 0 ? AppColors.primary : AppColors.protein,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 48,
                        color: isDark ? const Color(0x14FFFFFF) : Colors.grey.shade200,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'FASTING PROTOCOL',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                                color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            RichText(
                              text: TextSpan(
                                text: scheduleLabel.split(' ').first,
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                ),
                                children: const [
                                  TextSpan(
                                    text: ' window',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${eatUntilTime.format(context)} to ${eatFromTime.format(context)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Primary CTA Button ──
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEating
                          ? 'Eating window closed. Fasting protocol activated!'
                          : 'Fasting protocol ended. Eating window opened!'),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, Color(0xFF00C853)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isEating ? Icons.nights_stay_rounded : Icons.restaurant_rounded,
                        color: Colors.black,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isEating
                            ? 'START FASTING PROTOCOL (CLOSE WINDOW)'
                            : 'START EATING WINDOW (LOG MEAL)',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String text, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildCalorieBarChart({
    required List<double> dayCals,
    required List<String> dates,
    required double targetCalories,
    required bool isDark,
  }) {
    final days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final maxCal = [targetCalories * 1.1, ...dayCals].reduce((a, b) => a > b ? a : b);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (i) {
        final cal = i < dayCals.length ? dayCals[i] : 0.0;
        final dateStr = i < dates.length ? dates[i] : '';
        final isToday = dateStr == todayStr;
        final heightRatio = maxCal > 0 ? (cal / maxCal).clamp(0.06, 1.0) : 0.06;

        return Column(
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              height: 14,
              child: cal > 0
                  ? Text(
                      cal.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: isToday ? AppColors.primary : (isDark ? AppColors.textSecondaryDark : Colors.grey.shade600),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            Container(
              width: 32,
              height: 100 * heightRatio,
              decoration: BoxDecoration(
                color: isToday
                    ? (cal > targetCalories ? Colors.redAccent : AppColors.primary)
                    : (cal > 0
                        ? (isDark ? const Color(0xFF2E384D) : Colors.grey.shade400)
                        : (isDark ? const Color(0xFF1E232F) : Colors.grey.shade200)),
                borderRadius: BorderRadius.circular(6),
                boxShadow: isToday && cal > 0
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              days[i],
              style: TextStyle(
                fontSize: 10,
                fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                color: isToday
                    ? AppColors.primary
                    : (isDark ? AppColors.textSecondaryDark : Colors.grey.shade600),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _FastingRingPainter extends CustomPainter {
  final double progress;
  final bool isEating;

  _FastingRingPainter({required this.progress, required this.isEating});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 24) / 2;
    const strokeWidth = 14.0;

    // Background track
    final bgPaint = Paint()
      ..color = const Color(0xFF1B202C)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Fasting active glowing arc
    final activePaint = Paint()
      ..color = isEating ? AppColors.eating : AppColors.primary
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      activePaint,
    );

    // Glow effect
    final glowPaint = Paint()
      ..color = (isEating ? AppColors.eating : AppColors.primary).withValues(alpha: 0.3)
      ..strokeWidth = strokeWidth + 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _FastingRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.isEating != isEating;
}
