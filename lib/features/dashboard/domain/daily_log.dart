import 'package:eatwise/features/food_ai/domain/food_item.dart';
import 'package:equatable/equatable.dart';

class DailyLog extends Equatable {
  final String id;
  final String userId;
  final DateTime date;
  final List<FoodItem> foodEntries;
  final MealAnalysis? latestMeal;
  final double targetCalories;
  final double totalConsumedCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFats;

  const DailyLog({
    required this.id,
    required this.userId,
    required this.date,
    this.foodEntries = const [],
    this.latestMeal,
    this.targetCalories = 2000,
    this.totalConsumedCalories = 0,
    this.totalProtein = 0,
    this.totalCarbs = 0,
    this.totalFats = 0,
  });

  double get remainingCalories => targetCalories - totalConsumedCalories;
  double get progressRatio =>
      targetCalories > 0 ? totalConsumedCalories / targetCalories : 0;

  @override
  List<Object?> get props => [
        id,
        userId,
        date,
        foodEntries,
        totalConsumedCalories,
        totalProtein,
        totalCarbs,
        totalFats,
      ];
}

class MacroSummary extends Equatable {
  final double protein;
  final double carbs;
  final double fats;
  final double calories;

  const MacroSummary({
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.calories,
  });

  static const empty = MacroSummary(
    protein: 0,
    carbs: 0,
    fats: 0,
    calories: 0,
  );

  @override
  List<Object?> get props => [protein, carbs, fats, calories];
}
