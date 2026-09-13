import 'package:flutter_test/flutter_test.dart';
import 'package:eatwise/core/ai/ai_fallback_orchestrator.dart';
import 'package:eatwise/features/dashboard/presentation/providers/daily_insight_provider.dart';

void main() {
  group('AI Coach Sample Inputs Offline Baseline Matching', () {
    late AiFallbackOrchestrator orchestrator;

    setUp(() {
      orchestrator = AiFallbackOrchestrator();
    });

    tearDown(() {
      orchestrator.dispose();
    });

    test('parses "1 bowl Sinigang na Baboy & 1 cup rice"', () async {
      final res = await orchestrator.analyzeFood(text: '1 bowl Sinigang na Baboy & 1 cup rice');
      expect(res.mealAnalysis.foods, isNotEmpty);
      expect(res.mealAnalysis.totalCalories, greaterThan(300));
      expect(res.mealAnalysis.totalProtein, greaterThan(15));
    });

    test('parses "Chicken Inasal with sinangag"', () async {
      final res = await orchestrator.analyzeFood(text: 'Chicken Inasal with sinangag');
      expect(res.mealAnalysis.foods, isNotEmpty);
      expect(res.mealAnalysis.totalCalories, greaterThan(350));
      expect(res.mealAnalysis.totalProtein, greaterThan(20));
    });

    test('parses "2 boiled eggs & 1 pandesal"', () async {
      final res = await orchestrator.analyzeFood(text: '2 boiled eggs & 1 pandesal');
      expect(res.mealAnalysis.foods, isNotEmpty);
      expect(res.mealAnalysis.totalCalories, greaterThan(180));
      expect(res.mealAnalysis.totalProtein, greaterThan(12));
    });

    test('parses "Tapsilog with sunny side egg"', () async {
      final res = await orchestrator.analyzeFood(text: 'Tapsilog with sunny side egg');
      expect(res.mealAnalysis.foods, isNotEmpty);
      expect(res.mealAnalysis.totalCalories, greaterThan(400));
    });

    test('parses "1 bowl Arroz Caldo with egg"', () async {
      final res = await orchestrator.analyzeFood(text: '1 bowl Arroz Caldo with egg');
      expect(res.mealAnalysis.foods, isNotEmpty);
      expect(res.mealAnalysis.totalCalories, greaterThan(200));
    });
  });

  group('Daily Insight Zero Eaten Guard', () {
    test('RemainingMacros correctly indicates zero consumed calories', () {
      const remaining = RemainingMacros(
        calories: 1600,
        protein: 120,
        carbs: 180,
        fats: 45,
        consumedCalories: 0,
      );

      expect(remaining.consumedCalories, equals(0.0));
      expect(remaining.calories, equals(1600.0));
    });
  });

  group('Hero Dial Remaining Budget Ratio', () {
    test('when consumed is 0, remaining ratio is 1.0 (full circle)', () {
      const target = 1600.0;
      const consumed = 0.0;
      final remaining = target - consumed;
      final ratio = target > 0 ? (remaining / target).clamp(0.0, 1.0) : 0.0;

      expect(ratio, equals(1.0));
    });

    test('when consumed is 800, remaining ratio is 0.5 (half circle)', () {
      const target = 1600.0;
      const consumed = 800.0;
      final remaining = target - consumed;
      final ratio = target > 0 ? (remaining / target).clamp(0.0, 1.0) : 0.0;

      expect(ratio, equals(0.5));
    });
  });
}
