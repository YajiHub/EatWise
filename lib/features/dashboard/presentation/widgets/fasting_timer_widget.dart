import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eatwise/core/constants/app_colors.dart';
import 'package:eatwise/core/database/app_database.dart';

final _fastingSettingsProvider = FutureProvider<Map<String, String>>((ref) async {
  final startH = await AppDatabase.getSetting('fasting_start_hour');
  final startM = await AppDatabase.getSetting('fasting_start_minute');
  final endH = await AppDatabase.getSetting('fasting_end_hour');
  final endM = await AppDatabase.getSetting('fasting_end_minute');
  return {
    'startH': startH ?? '20',
    'startM': startM ?? '0',
    'endH': endH ?? '12',
    'endM': endM ?? '0',
  };
});

final fastingStartTimeProvider = StateProvider<TimeOfDay>((ref) {
  final s = ref.watch(_fastingSettingsProvider);
  return TimeOfDay(hour: int.tryParse(s.valueOrNull?['startH'] ?? '20') ?? 20, minute: int.tryParse(s.valueOrNull?['startM'] ?? '0') ?? 0);
});
final fastingEndTimeProvider = StateProvider<TimeOfDay>((ref) {
  final s = ref.watch(_fastingSettingsProvider);
  return TimeOfDay(hour: int.tryParse(s.valueOrNull?['endH'] ?? '12') ?? 12, minute: int.tryParse(s.valueOrNull?['endM'] ?? '0') ?? 0);
});

/// Compact status-only fasting widget for the dashboard. Schedule editing
/// lives in the Settings screen to keep the dashboard uncluttered.
class FastingTimerWidget extends ConsumerStatefulWidget {
  const FastingTimerWidget({super.key});

  @override
  ConsumerState<FastingTimerWidget> createState() => _FastingTimerWidgetState();
}

class _FastingTimerWidgetState extends ConsumerState<FastingTimerWidget>
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
    final eatUntilTime = ref.watch(fastingStartTimeProvider); // fast-start = eating ends
    final eatFromTime = ref.watch(fastingEndTimeProvider);    // fast-end = eating starts

    final eatUntilMin = eatUntilTime.hour * 60 + eatUntilTime.minute;
    final eatFromMin = eatFromTime.hour * 60 + eatFromTime.minute;

    final int eatingMin;
    if (eatUntilMin >= eatFromMin) {
      eatingMin = eatUntilMin - eatFromMin;
    } else {
      eatingMin = (1440 - eatFromMin) + eatUntilMin;
    }
    final fastingMin = 1440 - eatingMin;
    final scheduleLabel = '${fastingMin ~/ 60}:${eatingMin ~/ 60}';

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

    final remaining = Duration(minutes: phaseDurationMin - elapsedMin);
    final elapsed = Duration(minutes: elapsedMin);
    final total = Duration(minutes: phaseDurationMin);
    final progress =
        phaseDurationMin > 0 ? (elapsedMin / phaseDurationMin).clamp(0.0, 1.0) : 0.0;

    final phaseLabel = isEating ? 'EATING WINDOW' : 'FASTING';
    final phaseIcon = isEating ? Icons.restaurant : Icons.nights_stay;
    final phaseColor = isEating ? AppColors.eating : AppColors.fasting;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(phaseIcon, color: phaseColor, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      phaseLabel,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: 1.1,
                          color: phaseColor),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => context.push('/settings'),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(scheduleLabel,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary)),
                        const SizedBox(width: 4),
                        const Icon(Icons.settings,
                            size: 14, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              _fmt(remaining),
              style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  letterSpacing: 3),
            ),
            const SizedBox(height: 2),
            Text(
              isEating ? 'until fasting begins' : 'until you can eat',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(phaseColor),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_fmt(elapsed)} elapsed',
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
                Text('${_fmt(total)} total',
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _fmt(Duration d) =>
    '${d.inHours.toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
