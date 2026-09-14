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

/// Smart offline / fallback macro recommendation engine tailored to Filipino snacks.
String _smartLocalMacroInsight(int cal, int p, int c, int f, int hour) {
  if (cal <= 0) {
    return 'Daily calorie ceiling reached (${cal.abs()} kcal over). Stay hydrated with cold sparkling water, calamansi infusion, or green tea.';
  }

  // Check which macro has the highest proportional need
  if (p >= 25 && p >= c / 2) {
    return 'Protein is your priority ($p g left). Best snacks: 2 boiled eggs (~14g P), a 95g can of Century Tuna in water (~19g P), or grilled chicken breast strips.';
  }
  if (c >= 45) {
    return 'Refuel your carbs ($c g left). Clean options: 1 boiled saba banana (~28g C), half a cup of warm oatmeal, or fresh papaya slices.';
  }
  if (f >= 15) {
    return 'Healthy fats needed ($f g left). Grab a small handful of roasted peanuts (mani) or half an avocado with a pinch of salt.';
  }
  if (cal <= 180) {
    return 'Pacing tight ($cal kcal left). Opt for low-calorie options: chilled cucumber slices with vinegar, clear nilaga broth, or unsweetened iced tea.';
  }

  return 'Balanced pacing! For your next bite, try Greek yogurt with sliced mango or 1 boiled egg with a small slice of whole wheat bread.';
}

/// Fetches a short AI snack suggestion based on the user's remaining macros.
/// Falls back gracefully if all AI providers are unavailable.
final dailyInsightProvider =
    FutureProvider.autoDispose.family<String, RemainingMacros>((ref, macros) async {
  final cal = macros.calories.round();
  final p = macros.protein.round();
  final c = macros.carbs.round();
  final f = macros.fats.round();
  final hour = DateTime.now().hour;

  // Zero-eaten guard: User hasn't logged anything today yet
  if (macros.consumedCalories <= 0) {
    if (hour < 11) {
      return 'No meals logged yet today. Kick off your morning with protein (such as 2 boiled eggs & pandesal or Greek yogurt) to pace your ${cal > 0 ? "$cal kcal" : "daily"} target.';
    } else if (hour < 16) {
      return 'No meals logged yet today. Anchor your afternoon with a balanced Filipino lunch like grilled chicken inasal or fish with rice to fuel your day.';
    } else {
      return 'No meals logged yet today. Fuel your evening with a high-protein, nutrient-dense dinner to make steady progress toward your ${cal > 0 ? "$cal kcal" : "daily"} target.';
    }
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
    final result = await service.sendMessage(prompt.toString(), saveToHistory: false);
    final text = result.text.trim();
    if (text.isEmpty ||
        text.contains('tracked on your Hub screen') ||
        text.contains('offline mode with access to the FNRI')) {
      return _smartLocalMacroInsight(cal, p, c, f, hour);
    }
    return text;
  } catch (_) {
    return _smartLocalMacroInsight(cal, p, c, f, hour);
  }
});
