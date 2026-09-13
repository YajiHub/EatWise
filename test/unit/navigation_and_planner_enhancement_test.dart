import 'package:flutter_test/flutter_test.dart';
import 'package:eatwise/features/planner/data/workout_preset.dart';
import 'package:eatwise/features/dashboard/presentation/widgets/fasting_timer_widget.dart';

void main() {
  group('Daily Planner Routine Presets', () {
    const testDate = '2026-09-13';

    test('homeWorkoutPreset returns valid non-empty structured blocks', () {
      final tasks = homeWorkoutPreset(testDate);
      expect(tasks, isNotEmpty);
      expect(tasks.length, greaterThanOrEqualTo(10));
      for (final t in tasks) {
        expect(t['task_date'], equals(testDate));
        expect(t['category'], equals('workout'));
        expect(t['title'], isNotEmpty);
      }
    });

    test('hydrationProteinPreset generates hydration & protein goals', () {
      final tasks = hydrationProteinPreset(testDate);
      expect(tasks, isNotEmpty);
      expect(tasks.length, greaterThanOrEqualTo(5));
      for (final t in tasks) {
        expect(t['task_date'], equals(testDate));
        expect(t['category'], equals('meal_plan'));
        expect(t['title'], isNotEmpty);
      }
      expect(tasks.any((t) => (t['title'] as String).contains('Water')), isTrue);
      expect(tasks.any((t) => (t['title'] as String).contains('Protein')), isTrue);
    });

    test('filipinoDietResetPreset generates balanced diet goals', () {
      final tasks = filipinoDietResetPreset(testDate);
      expect(tasks, isNotEmpty);
      expect(tasks.length, greaterThanOrEqualTo(5));
      for (final t in tasks) {
        expect(t['task_date'], equals(testDate));
        expect(t['title'], isNotEmpty);
      }
      expect(tasks.any((t) => (t['title'] as String).contains('Rice')), isTrue);
      expect(tasks.any((t) => (t['title'] as String).contains('Vegetable')), isTrue);
    });
  });

  group('Fasting on Hub State Notifier', () {
    test('ShowFastingOnHubNotifier initial default is true', () {
      final notifier = ShowFastingOnHubNotifier();
      expect(notifier.state, isTrue);
    });
  });
}
