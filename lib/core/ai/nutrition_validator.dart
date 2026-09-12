import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:eatwise/core/ai/ai_config.dart';
import 'package:eatwise/core/ai/ai_models.dart';
import 'package:eatwise/core/ai/local_food_db.dart';
import 'package:eatwise/features/food_ai/domain/food_item.dart';

/// Sanity checks for macro values
class _MacroSanityChecker {
  /// Max calories per 100g (extremely high-fat items cap at ~900)
  static const double maxCalPer100g = 900;
  
  /// Protein beyond this suggests error (>40g per 100g is extremely rare)
  static const double maxProteinPer100g = 50;
  
  /// Carbs beyond this (~80g per 100g is pure carbs)
  static const double maxCarbsPer100g = 100;
  
  /// Fat beyond this (~100g per 100g is pure fat)
  static const double maxFatPer100g = 100;
  
  /// Macro ratio validation: 4cal/g protein, 4cal/g carbs, 9cal/g fat ± margin
  static bool isValidMacroRatio(double cal, double protein, double carbs, double fat, {double tolerance = 0.15}) {
    if (cal <= 0) return false;
    
    final calculatedCal = (protein * 4) + (carbs * 4) + (fat * 9);
    final diff = (calculatedCal - cal).abs();
    final margin = cal * tolerance;
    
    return diff <= margin;
  }
  
  /// Portion size sanity check
  static bool isValidPortionSize(double grams) {
    return grams > 0 && grams <= 1000; // No portion is larger than 1kg
  }
}

class NutritionValidator {
  final LocalFoodDatabase _localDb = LocalFoodDatabase();
  final http.Client _client;

  NutritionValidator({http.Client? client}) : _client = client ?? http.Client();

  Future<AnalysisResult> validate(MealAnalysis aiResult) async {
    final validatedItems = <ValidatedFoodItem>[];

    for (final item in aiResult.foods) {
      debugPrint('[Validator] Processing: ${item.name} (${item.portionSizeGrams}g)');
      
      // Step 1: Sanity check the AI result
      final sanitized = _sanitizeAiResult(item);
      
      // Step 2: Try local database match first (fastest & most trusted for Filipino foods)
      final localMatch = _localDb.search(sanitized.name);
      if (localMatch != null && localMatch.confidence >= 0.7) {
        debugPrint('[Validator] ✓ Local DB match: ${localMatch.matchedName} (conf: ${localMatch.confidence})');
        validatedItems.add(_applyLocalMatch(sanitized, localMatch));
        continue;
      }

      // Step 3: Try OpenFoodFacts API (secondary validation)
      final offMatch = await _searchOpenFoodFacts(sanitized.name);
      if (offMatch != null) {
        debugPrint('[Validator] ✓ OpenFoodFacts match: ${offMatch.name}');
        validatedItems.add(_applyOffMatch(sanitized, offMatch));
        continue;
      }

      // Step 4: If AI result passes sanity checks, use it as-is
      if (_passesAllSanityChecks(sanitized)) {
        debugPrint('[Validator] ✓ AI result passes sanity checks');
        validatedItems.add(ValidatedFoodItem(item: sanitized, status: VerificationStatus.estimated, source: 'ai_validated'));
        continue;
      }

      // Step 5: Last resort - adjust the AI result based on heuristics
      final adjusted = _adjustBasedOnHeuristics(sanitized);
      debugPrint('[Validator] ⚠ Applied heuristic adjustments');
      validatedItems.add(ValidatedFoodItem(item: adjusted, status: VerificationStatus.estimated, source: 'ai_adjusted'));
    }

    // Recalculate totals from validated items
    final correctedTotalCal = validatedItems.fold<double>(0, (sum, v) => sum + v.item.calories);
    final correctedTotalP = validatedItems.fold<double>(0, (sum, v) => sum + v.item.proteinG);
    final correctedTotalC = validatedItems.fold<double>(0, (sum, v) => sum + v.item.carbsG);
    final correctedTotalF = validatedItems.fold<double>(0, (sum, v) => sum + v.item.fatsG);

    final correctedMeal = MealAnalysis(
      foods: validatedItems.map((v) => v.item).toList(),
      totalCalories: correctedTotalCal,
      totalProtein: correctedTotalP,
      totalCarbs: correctedTotalC,
      totalFats: correctedTotalF,
      summary: aiResult.summary,
    );

    return AnalysisResult(
      items: validatedItems,
      mealAnalysis: correctedMeal,
    );
  }

  /// Sanitize AI result by fixing obvious errors
  FoodItem _sanitizeAiResult(FoodItem item) {
    var sanitized = item;
    
    // Fix portion size if invalid
    if (!_MacroSanityChecker.isValidPortionSize(sanitized.portionSizeGrams)) {
      final normalized = sanitized.portionSizeGrams.clamp(10.0, 500.0);
      debugPrint('[Validator] ⚠ Adjusted portion: ${sanitized.portionSizeGrams}g → ${normalized}g');
      sanitized = sanitized.copyWith(portionSizeGrams: normalized);
    }

    // Fix obviously wrong calories
    if (sanitized.calories < 0) {
      sanitized = sanitized.copyWith(calories: 0);
    } else if (sanitized.calories > sanitized.portionSizeGrams * 10) {
      // More than 10 cal/gram is impossible
      final adjusted = sanitized.portionSizeGrams * 8;
      debugPrint('[Validator] ⚠ Adjusted calories: ${sanitized.calories} → $adjusted');
      sanitized = sanitized.copyWith(calories: adjusted);
    }

    // Clamp macros to reasonable ranges per portion
    final maxCalForPortion = sanitized.portionSizeGrams * 9; // Max ~900cal/100g × portion
    if (sanitized.calories > maxCalForPortion) {
      sanitized = sanitized.copyWith(calories: maxCalForPortion);
    }

    if (sanitized.proteinG < 0) sanitized = sanitized.copyWith(proteinG: 0);
    if (sanitized.carbsG < 0) sanitized = sanitized.copyWith(carbsG: 0);
    if (sanitized.fatsG < 0) sanitized = sanitized.copyWith(fatsG: 0);

    return sanitized;
  }

  /// Check if food item passes all sanity validations
  bool _passesAllSanityChecks(FoodItem item) {
    // Portion size check
    if (!_MacroSanityChecker.isValidPortionSize(item.portionSizeGrams)) {
      debugPrint('[Validator] ✗ Invalid portion size: ${item.portionSizeGrams}g');
      return false;
    }

    // Per-100g calculations for validation
    final cal100g = (item.calories / item.portionSizeGrams) * 100;
    final p100g = (item.proteinG / item.portionSizeGrams) * 100;
    final c100g = (item.carbsG / item.portionSizeGrams) * 100;
    final f100g = (item.fatsG / item.portionSizeGrams) * 100;

    // Individual macro bounds
    if (cal100g > _MacroSanityChecker.maxCalPer100g) {
      debugPrint('[Validator] ✗ Calories too high: ${cal100g}cal/100g');
      return false;
    }
    if (p100g > _MacroSanityChecker.maxProteinPer100g) {
      debugPrint('[Validator] ✗ Protein too high: ${p100g}g/100g');
      return false;
    }
    if (c100g > _MacroSanityChecker.maxCarbsPer100g) {
      debugPrint('[Validator] ✗ Carbs too high: ${c100g}g/100g');
      return false;
    }
    if (f100g > _MacroSanityChecker.maxFatPer100g) {
      debugPrint('[Validator] ✗ Fat too high: ${f100g}g/100g');
      return false;
    }

    // Macro ratio validation (allow 20% tolerance due to fiber, water, etc.)
    if (!_MacroSanityChecker.isValidMacroRatio(cal100g, p100g, c100g, f100g, tolerance: 0.20)) {
      debugPrint('[Validator] ⚠ Macro ratio seems off but within tolerance');
      // Don't fail on this alone - could be high-fiber foods
    }

    // Confidence check
    if (item.confidence < 0.3) {
      debugPrint('[Validator] ✗ Confidence too low: ${item.confidence}');
      return false;
    }

    return true;
  }

  /// Apply heuristic adjustments when AI result is questionable
  FoodItem _adjustBasedOnHeuristics(FoodItem item) {
    var adjusted = item;
    final cal100g = (item.calories / item.portionSizeGrams) * 100;

    // If calories seem too high, scale down proportionally
    if (cal100g > 500) {
      final scaleFactor = 450 / cal100g;
      adjusted = adjusted.copyWith(
        calories: item.calories * scaleFactor,
        proteinG: item.proteinG * scaleFactor,
        carbsG: item.carbsG * scaleFactor,
        fatsG: item.fatsG * scaleFactor,
        reasoning: '${item.reasoning} [SCALED: caloric density adjusted]',
      );
      debugPrint('[Validator] Scaled down item by ${((1 - scaleFactor) * 100).toStringAsFixed(1)}%');
    }

    // If macros are severely misaligned, recalculate
    if (!_MacroSanityChecker.isValidMacroRatio(item.calories, item.proteinG, item.carbsG, item.fatsG, tolerance: 0.25)) {
      // Assume reasonable ratios: 20% protein, 50% carbs, 30% fat
      final proteinCal = item.calories * 0.20;
      final carbsCal = item.calories * 0.50;
      final fatsCal = item.calories * 0.30;

      adjusted = adjusted.copyWith(
        proteinG: proteinCal / 4,
        carbsG: carbsCal / 4,
        fatsG: fatsCal / 9,
        reasoning: '${item.reasoning} [MACRO REBALANCED]',
      );
      debugPrint('[Validator] Rebalanced macros with 20:50:30 ratio');
    }

    return adjusted;
  }

  ValidatedFoodItem _applyLocalMatch(FoodItem aiItem, LocalFoodMatch match) {
    final actualGrams = _resolvePortionGrams(aiItem, match);
    final scale = actualGrams / 100.0;

    final corrected = aiItem.copyWith(
      portionSizeGrams: actualGrams,
      calories: match.calPer100g * scale,
      proteinG: match.proteinPer100g * scale,
      carbsG: match.carbsPer100g * scale,
      fatsG: match.fatPer100g * scale,
      confidence: match.confidence,
      reasoning: 'Verified: ${match.matchedName} (local DB)',
    );
    return ValidatedFoodItem(item: corrected, status: VerificationStatus.verified, source: 'local_db');
  }

  ValidatedFoodItem _applyOffMatch(FoodItem aiItem, _OffProduct product) {
    final scale = aiItem.portionSizeGrams > 0 ? aiItem.portionSizeGrams / 100 : 1.0;
    final corrected = aiItem.copyWith(
      name: product.name,
      calories: product.calPer100g * scale,
      proteinG: product.proteinPer100g * scale,
      carbsG: product.carbsPer100g * scale,
      fatsG: product.fatPer100g * scale,
      confidence: 0.85,
      reasoning: 'Verified: ${product.name} (Open Food Facts)',
    );
    return ValidatedFoodItem(item: corrected, status: VerificationStatus.verified, source: 'open_food_facts');
  }

  double _resolvePortionGrams(FoodItem aiItem, LocalFoodMatch match) {
    if (match.gramsPerServing == null || match.gramsPerServing! <= 0) {
      return aiItem.portionSizeGrams > 0 ? aiItem.portionSizeGrams : 100.0;
    }

    final quantity = _parseQuantity(aiItem.portionDescription);
    return match.gramsPerServing! * quantity;
  }

  int _parseQuantity(String description) {
    if (description.isEmpty) return 1;

    final match = RegExp(r'(\d+(?:\.\d+)?)(?:\s*(?:piece|pc|pcs|pieces?|cup|cups?|medium|large|small|stick|slice|scoop|glass|bowl|plate|serving|regular|sachet))?').firstMatch(description.toLowerCase());
    if (match != null) {
      final num = double.tryParse(match.group(1) ?? '');
      if (num != null && num > 0) return max(1, num.round());
    }

    final wordMap = {'a ': 1, 'an ': 1, 'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5, 'half a ': 1, 'half': 1};
    final lower = description.toLowerCase();
    for (final entry in wordMap.entries) {
      if (lower.startsWith(entry.key) || lower.contains(' ${entry.key}')) {
        return entry.value;
      }
    }

    return 1;
  }

  Future<_OffProduct?> _searchOpenFoodFacts(String query) async {
    try {
      final uri = Uri.parse('${AiConfig.openFoodFactsBaseUrl}/search.pl?search_terms=${Uri.encodeComponent(query)}&json=1&page_size=1');
      final response = await _client.get(uri, headers: {'User-Agent': 'EatWise/1.0'}).timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      final products = data['products'] as List<dynamic>?;
      if (products == null || products.isEmpty) return null;

      final product = products.first as Map<String, dynamic>;
      final nutriments = product['nutriments'] as Map<String, dynamic>?;
      if (nutriments == null) return null;

      final cal = (nutriments['energy-kcal_100g'] as num?)?.toDouble();
      final p = (nutriments['proteins_100g'] as num?)?.toDouble();
      final c = (nutriments['carbohydrates_100g'] as num?)?.toDouble();
      final f = (nutriments['fat_100g'] as num?)?.toDouble();

      if (cal == null || p == null || c == null || f == null) return null;

      return _OffProduct(
        name: product['product_name'] as String? ?? query,
        calPer100g: cal,
        proteinPer100g: p,
        carbsPer100g: c,
        fatPer100g: f,
      );
    } catch (_) {
      return null;
    }
  }

  void dispose() => _client.close();
}

class _OffProduct {
  final String name;
  final double calPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;

  const _OffProduct({
    required this.name,
    required this.calPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
  });
}
