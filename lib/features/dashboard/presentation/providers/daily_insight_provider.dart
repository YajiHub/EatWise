import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eatwise/features/food_ai/presentation/providers/gemini_provider.dart';

/// Remaining macros for the day, used to key the insight provider.
class RemainingMacros {
  final double calories;
  final double protein;
  final double carbs;
  final double fats;
  final double consumedCalories;

  const RemainingMacros({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    this.consumedCalories = 0.0,
  });

  /// Rounds to limit AI re-query churn (cal→nearest 50, macros→nearest 5).
  String get cacheKey {
    final rCal = (calories / 50).round() * 50;
    final rP = (protein / 5).round() * 5;
    final rC = (carbs / 5).round() * 5;
    final rF = (fats / 5).round() * 5;
    final rConsumed = (consumedCalories / 50).round() * 50;
    return '$rCal|$rP|$rC|$rF|$rConsumed';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RemainingMacros &&
          runtimeType == other.runtimeType &&
          cacheKey == other.cacheKey;

  @override
  int get hashCode => cacheKey.hashCode;
}

/// Fetches a short AI snack suggestion based on the user's remaining macros.
/// Falls back gracefully if all AI providers are unavailable.
final dailyInsightProvider =
    FutureProvider.autoDispose.family<String, RemainingMacros>((ref, macros) async {
  final cal = macros.calories.round();
  final p = macros.protein.round();
  final c = macros.carbs.round();
  final f = macros.fats.round();

  // Zero-eaten guard: User hasn't logged anything today yet
  if (macros.consumedCalories <= 0) {
    return 'No meals logged yet today. Kick off your day with a protein-rich meal (such as eggs, chicken inasal, or greek yogurt) to pace your ${cal > 0 ? "$cal kcal" : "daily"} target.';
  }

  final service = ref.watch(askAiServiceProvider);

  final prompt = StringBuffer()
    ..writeln('You are MacroAI, an intelligent nutrition assistant inside the EatWise app.')
    ..writeln('The user has consumed ${macros.consumedCalories.round()} kcal and has the following macros remaining for today:')
    ..writeln('- Calories: ${cal >= 0 ? cal : 0} (goal ${cal < 0 ? "exceeded by ${(-cal)}" : "remaining"})')
    ..writeln('- Protein: ${p}g ${p < 0 ? "(over by ${(-p)}g)" : "remaining"}')
    ..writeln('- Carbs: ${c}g ${c < 0 ? "(over by ${(-c)}g)" : "remaining"}')
    ..writeln('- Fats: ${f}g ${f < 0 ? "(over by ${(-f)}g)" : "remaining"}')
    ..writeln('')
    ..writeln('Suggest 2-3 specific, practical snacks that fit these remaining macros.')
    ..writeln('For each snack: give the food name, an approximate portion, and a one-line reason.')
    ..writeln('If protein is the most lacking macro, prioritize high-protein options.')
    ..writeln('Keep the total response under 60 words. Plain text only, no markdown, no JSON.')
    ..writeln('Provide a concise, encouraging 1-sentence opening mentioning their macro balance, followed by the snack recommendations.');

  try {
    final result = await service.sendMessage(prompt.toString());
    return result.text.trim();
  } catch (_) {
    // Graceful, rule-based fallback — no AI required.
    if (cal <= 0) {
      return 'You have reached your daily calorie goal. Consider herbal tea or sparkling water if you feel hungry.';
    }
    if (p > 0 && p <= c && p <= f) {
      return 'Low on protein? Try Greek yogurt with berries, a hard-boiled egg, or a tuna scoop — quick and protein-dense.';
    }
    return 'A banana with peanut butter or a small handful of trail mix fits your remaining macros nicely.';
  }
});
