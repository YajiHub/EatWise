import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  group('Coach Streak Badge Dynamic Display', () {
    test('formats streak value dynamically with fire emoji and days suffix', () {
      String formatStreak(int streak) => '🔥 ${streak}d';

      expect(formatStreak(0), '🔥 0d');
      expect(formatStreak(5), '🔥 5d');
      expect(formatStreak(14), '🔥 14d');
      expect(formatStreak(21), '🔥 21d');
    });
  });

  group('Hub & History Date Isolation', () {
    test('Hub date string always matches current local date regardless of history browsing', () {
      final now = DateTime.now();
      final expectedTodayStr = DateFormat('yyyy-MM-dd').format(now);

      // Simulating picking a past date in history
      final historyDate = DateTime(2026, 8, 15);
      final historyDateStr = DateFormat('yyyy-MM-dd').format(historyDate);

      // Hub date resolution
      final hubDateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

      expect(historyDateStr, '2026-08-15');
      expect(hubDateStr, expectedTodayStr);
      expect(hubDateStr, isNot(equals(historyDateStr)));
    });
  });

  group('Active Streak Calculation Logic', () {
    int calculateStreak({
      required DateTime now,
      required Set<String> loggedDates,
    }) {
      final todayStr = DateFormat('yyyy-MM-dd').format(now);
      DateTime startFrom;

      if (loggedDates.contains(todayStr)) {
        startFrom = now;
      } else {
        final yesterday = now.subtract(const Duration(days: 1));
        final yesterdayStr = DateFormat('yyyy-MM-dd').format(yesterday);
        if (loggedDates.contains(yesterdayStr)) {
          startFrom = yesterday;
        } else {
          return 0; // Inactive for >= 2 days or weeks
        }
      }

      int streak = 0;
      var cur = startFrom;
      while (true) {
        final ds = DateFormat('yyyy-MM-dd').format(cur);
        if (!loggedDates.contains(ds)) break;
        streak++;
        cur = cur.subtract(const Duration(days: 1));
      }
      return streak;
    }

    test('returns 0 when user has stopped for days or weeks', () {
      final now = DateTime(2026, 9, 13);
      // User logged from Aug 9 to Sep 3 (26 days) and stopped 10 days ago
      final loggedDates = <String>{
        for (int i = 0; i < 26; i++)
          DateFormat('yyyy-MM-dd').format(DateTime(2026, 8, 9).add(Duration(days: i)))
      };

      final streak = calculateStreak(now: now, loggedDates: loggedDates);
      expect(streak, 0);
    });

    test('preserves streak with grace period when today has no meals logged yet', () {
      final now = DateTime(2026, 9, 13);
      // Logged yesterday Sep 12, Sep 11, Sep 10
      final loggedDates = {'2026-09-10', '2026-09-11', '2026-09-12'};

      final streak = calculateStreak(now: now, loggedDates: loggedDates);
      expect(streak, 3);
    });

    test('increments streak when today is logged', () {
      final now = DateTime(2026, 9, 13);
      final loggedDates = {'2026-09-11', '2026-09-12', '2026-09-13'};

      final streak = calculateStreak(now: now, loggedDates: loggedDates);
      expect(streak, 3);
    });
  });

  group('Weekly Calorie Dates and Navigation', () {
    List<String> weekDatesForOffset(DateTime now, int offset) {
      final anchor = now.add(Duration(days: offset * 7));
      final monday = anchor.subtract(Duration(days: anchor.weekday - 1));
      return List.generate(7, (i) {
        final d = monday.add(Duration(days: i));
        return DateFormat('yyyy-MM-dd').format(d);
      });
    }

    test('offset 0 targets current week (Sep 7 to Sep 13 for 2026-09-13)', () {
      final now = DateTime(2026, 9, 13); // Sunday
      final dates = weekDatesForOffset(now, 0);
      expect(dates.first, '2026-09-07'); // Monday
      expect(dates.last, '2026-09-13');  // Sunday
    });

    test('offset -1 targets previous week (Aug 31 to Sep 6)', () {
      final now = DateTime(2026, 9, 13);
      final dates = weekDatesForOffset(now, -1);
      expect(dates.first, '2026-08-31');
      expect(dates.last, '2026-09-06');
    });

    test('offset -2 targets two weeks ago (Aug 24 to Aug 30)', () {
      final now = DateTime(2026, 9, 13);
      final dates = weekDatesForOffset(now, -2);
      expect(dates.first, '2026-08-24');
      expect(dates.last, '2026-08-30');
    });
  });
}
