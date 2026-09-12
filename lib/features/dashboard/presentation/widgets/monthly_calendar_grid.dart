import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:eatwise/features/dashboard/providers/calendar_provider.dart';
import 'package:eatwise/features/dashboard/presentation/screens/dashboard_screen.dart';

class MonthlyCalendarGrid extends ConsumerStatefulWidget {
  const MonthlyCalendarGrid({super.key});

  @override
  ConsumerState<MonthlyCalendarGrid> createState() => _MonthlyCalendarGridState();
}

class _MonthlyCalendarGridState extends ConsumerState<MonthlyCalendarGrid> {
  int _displayMonth = 0;
  int _displayYear = 0;

  @override
  void initState() {
    super.initState();
    _syncToSelectedDate();
  }

  void _syncToSelectedDate() {
    final d = ref.read(selectedDateProvider);
    _displayMonth = d.month;
    _displayYear = d.year;
  }

  void _prevMonth() {
    setState(() {
      if (_displayMonth == 1) {
        _displayMonth = 12;
        _displayYear--;
      } else {
        _displayMonth--;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      if (_displayMonth == 12) {
        _displayMonth = 1;
        _displayYear++;
      } else {
        _displayMonth++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dayCaloriesAsync = ref.watch(calendarProvider((_displayYear, _displayMonth)));
    final dayCalories = dayCaloriesAsync.valueOrNull ?? <int, double>{};
    final selectedDate = ref.watch(selectedDateProvider);
    final targetCal = ref.watch(targetCaloriesProvider);
    final today = DateTime.now();
    final monthName = DateFormat('MMMM yyyy').format(DateTime(_displayYear, _displayMonth));

    final firstDay = DateTime(_displayYear, _displayMonth, 1);
    final lastDay = DateTime(_displayYear, _displayMonth + 1, 0);
    final startWeekday = firstDay.weekday % 7;
    final daysInMonth = lastDay.day;

    final cells = <Widget>[];
    for (var i = 0; i < startWeekday; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_displayYear, _displayMonth, day);
      final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
      final isSelected = date.year == selectedDate.year && date.month == selectedDate.month && date.day == selectedDate.day;
      final dayTotal = dayCalories[day];
      final hasLog = dayTotal != null;
      final isOverTarget = hasLog && dayTotal > targetCal;
      final isFuture = date.isAfter(today);

      cells.add(
        GestureDetector(
          onTap: isFuture ? null : () => ref.read(selectedDateProvider.notifier).state = date,
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
              borderRadius: BorderRadius.circular(8),
              border: isToday && !isSelected
                  ? Border.all(color: Theme.of(context).colorScheme.primary, width: 1.5)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    color: isFuture ? Colors.grey.shade400 : null,
                  ),
                ),
                const SizedBox(height: 2),
                if (hasLog)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isOverTarget ? Colors.redAccent : Colors.greenAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(onPressed: _prevMonth, icon: const Icon(Icons.chevron_left), iconSize: 22),
                GestureDetector(
                  onTap: () {
                    ref.read(selectedDateProvider.notifier).state = DateTime.now();
                    _syncToSelectedDate();
                  },
                  child: Text(monthName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
                IconButton(onPressed: _nextMonth, icon: const Icon(Icons.chevron_right), iconSize: 22),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: const ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su']
                  .map((d) => Expanded(
                        child: Center(
                          child: Text(d, style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 4),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.1,
              children: cells,
            ),
            if (hasAnyLogs(dayCalories))
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _legendDot(Colors.greenAccent, 'Under'),
                    const SizedBox(width: 12),
                    _legendDot(Colors.redAccent, 'Over'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool hasAnyLogs(Map<int, double> dayCalories) => dayCalories.isNotEmpty;

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
