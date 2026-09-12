import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Shared JSON parsing logic used by both Gemini and Groq providers.
/// Enhanced to handle long inputs, truncation, and multiple food items.
class AiJsonParser {
  /// Parse a raw AI response into a Map, handling markdown fences and truncation.
  /// Implements aggressive repair strategies for truncated/malformed JSON.
  static Map<String, dynamic> parseJsonResponse(String rawJson) {
    debugPrint('[AiJsonParser] Raw response: ${rawJson.length} chars');
    
    var cleaned = _preprocessJson(rawJson);
    debugPrint('[AiJsonParser] After preprocess: ${cleaned.length} chars');

    try {
      final result = jsonDecode(cleaned) as Map<String, dynamic>;
      debugPrint('[AiJsonParser] ✓ Tier 1 (standard parse) - SUCCESS');
      return result;
    } on FormatException catch (e1) {
      debugPrint('[AiJsonParser] ✗ Tier 1 failed: ${e1.message}');
      
      // Attempt 1: Simple truncation repair
      cleaned = _repairTruncatedJson(cleaned);
      try {
        final result = jsonDecode(cleaned) as Map<String, dynamic>;
        debugPrint('[AiJsonParser] ✓ Tier 2 (truncation repair) - SUCCESS');
        return result;
      } on FormatException catch (e2) {
        debugPrint('[AiJsonParser] ✗ Tier 2 failed: ${e2.message}');
        
        // Attempt 2: Extract and fix individual food items
        cleaned = _repairMultiFoodJson(cleaned);
        try {
          final result = jsonDecode(cleaned) as Map<String, dynamic>;
          debugPrint('[AiJsonParser] ✓ Tier 3 (multi-food repair) - SUCCESS');
          return result;
        } on FormatException catch (e3) {
          debugPrint('[AiJsonParser] ✗ Tier 3 failed: ${e3.message}');
          
          // Attempt 3: Fallback structure with partial data
          debugPrint('[AiJsonParser] ✓ Tier 4 (fallback structure) - USING FALLBACK');
          return _createFallbackStructure(cleaned);
        }
      }
    }
  }

  /// Preprocess JSON: remove markdown, extract content
  static String _preprocessJson(String raw) {
    var cleaned = raw
        .trim()
        .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
        .replaceAll(RegExp(r'^```\s*$', multiLine: true), '')
        .replaceAll(RegExp(r'^\s*```\s*$', multiLine: true), '')
        .trim();

    // Find the first { and last } to extract JSON boundaries
    final firstBrace = cleaned.indexOf('{');
    final lastBrace = cleaned.lastIndexOf('}');
    if (firstBrace >= 0 && lastBrace > firstBrace) {
      cleaned = cleaned.substring(firstBrace, lastBrace + 1);
    }

    return cleaned;
  }

  static String _repairTruncatedJson(String raw) {
    var fixed = raw;

    // Remove trailing comma
    fixed = fixed.replaceAll(RegExp(r',\s*$'), '');

    final trimmed = fixed.trimRight();
    if (!trimmed.endsWith('}') && !trimmed.endsWith(']')) {
      // Handle unterminated string
      final quoteCount = '"'.allMatches(fixed).length;
      if (quoteCount.isOdd) {
        fixed = '${fixed.trimRight()}"';
      }

      // Close arrays
      final openBrackets = '['.allMatches(fixed).length;
      final closeBrackets = ']'.allMatches(fixed).length;
      for (var i = closeBrackets; i < openBrackets; i++) {
        fixed += ']';
      }

      // Close objects
      final openBraces = '{'.allMatches(fixed).length;
      final closeBraces = '}'.allMatches(fixed).length;
      for (var i = closeBraces; i < openBraces; i++) {
        fixed += '}';
      }
    }

    return fixed;
  }

  /// Special handling for multi-food responses that might be partially truncated
  static String _repairMultiFoodJson(String raw) {
    // If "foods" array is incomplete, try to complete it
    if (raw.contains('"foods"') && raw.contains('[')) {
      final foodsIndex = raw.indexOf('"foods"');
      final colonIndex = raw.indexOf(':', foodsIndex);
      if (colonIndex >= 0) {
        final bracketIndex = raw.indexOf('[', colonIndex);
        if (bracketIndex >= 0) {
          // Find if we're mid-item
          final bracketContent = raw.substring(bracketIndex);
          
          // Check if last item is incomplete
          if (bracketContent.contains('{') && !bracketContent.endsWith(']')) {
            // Try to close the last object in the foods array
            var repaired = raw;
            
            // Count braces in foods array
            final foodsBraceCount = '{'.allMatches(bracketContent).length;
            final foodsCloseBraceCount = '}'.allMatches(bracketContent).length;
            
            if (foodsBraceCount > foodsCloseBraceCount) {
              for (var i = foodsCloseBraceCount; i < foodsBraceCount; i++) {
                repaired += '}';
              }
              repaired += ']';
            }
            
            return repaired;
          }
        }
      }
    }

    return raw;
  }

  /// Create a fallback structure when JSON is too corrupted
  /// Extracts what we can and provides safe defaults
  static Map<String, dynamic> _createFallbackStructure(String partial) {
    try {
      // Try to extract at least the foods array — use greedy match to grab full array
      final foodsMatch = RegExp(r'"foods"\s*:\s*(\[[\s\S]*\])', dotAll: true).firstMatch(partial);
      final foods = <Map<String, dynamic>>[];

      if (foodsMatch != null) {
        final arrayRaw = foodsMatch.group(1)!;
        // Try to repair the array — find the last balanced ]
        var depth = 0;
        var endIdx = -1;
        for (var i = 0; i < arrayRaw.length; i++) {
          final ch = arrayRaw[i];
          if (ch == '[') depth++;
          if (ch == ']') {
            depth--;
            if (depth == 0) {
              endIdx = i + 1;
              break;
            }
          }
        }
        if (endIdx > 0) {
          final cleanArray = arrayRaw.substring(0, endIdx);
          try {
            final foodsParsed = jsonDecode(cleanArray) as List;
            foods.addAll(foodsParsed.cast<Map<String, dynamic>>());
          } catch (_) {
            // array parse failed, try item-by-item
            final itemMatches = RegExp(r'\{[^{}]*\}').allMatches(cleanArray);
            for (final m in itemMatches) {
              try {
                foods.add(jsonDecode(m.group(0)!) as Map<String, dynamic>);
              } catch (_) {}
            }
          }
        }
      }

      // Extract partial fields
      final totalCalMatch = RegExp(r'"total_calories"\s*:\s*(\d+(?:\.\d+)?)').firstMatch(partial);
      final totalCal = totalCalMatch != null ? double.parse(totalCalMatch.group(1)!) : null;
      final totalPMatch = RegExp(r'"total_protein_g"\s*:\s*(\d+(?:\.\d+)?)').firstMatch(partial);
      final totalP = totalPMatch != null ? double.parse(totalPMatch.group(1)!) : null;
      final totalCMatch = RegExp(r'"total_carbs_g"\s*:\s*(\d+(?:\.\d+)?)').firstMatch(partial);
      final totalC = totalCMatch != null ? double.parse(totalCMatch.group(1)!) : null;
      final totalFMatch = RegExp(r'"total_fats_g"\s*:\s*(\d+(?:\.\d+)?)').firstMatch(partial);
      final totalF = totalFMatch != null ? double.parse(totalFMatch.group(1)!) : null;

      // Compute totals from foods if we have them
      final double computedCal;
      final double computedP;
      final double computedC;
      final double computedF;
      if (totalCal != null) {
        computedCal = totalCal;
      } else {
        computedCal = foods.fold<double>(0, (s, f) => s + ((f['calories'] as num?)?.toDouble() ?? 0));
      }
      if (totalP != null) {
        computedP = totalP;
      } else {
        computedP = foods.fold<double>(0, (s, f) => s + ((f['protein_g'] as num?)?.toDouble() ?? 0));
      }
      if (totalC != null) {
        computedC = totalC;
      } else {
        computedC = foods.fold<double>(0, (s, f) => s + ((f['carbs_g'] as num?)?.toDouble() ?? 0));
      }
      if (totalF != null) {
        computedF = totalF;
      } else {
        computedF = foods.fold<double>(0, (s, f) => s + ((f['fats_g'] as num?)?.toDouble() ?? 0));
      }

      if (foods.isNotEmpty) {
        return {
          'foods': foods,
          'meal_type': 'snack',
          'total_calories': computedCal,
          'total_protein_g': computedP,
          'total_carbs_g': computedC,
          'total_fats_g': computedF,
          'summary': 'Logged: ${foods.length} item(s) from partial analysis — please verify macros.'
        };
      }

      return {
        'foods': [{
          'name': 'Could not parse — please try again',
          'name_tagalog': 'Hindi ma-parse',
          'portion_size_g': 100,
          'portion_description': '1 serving',
          'calories': computedCal > 0 ? computedCal : 200,
          'protein_g': computedP > 0 ? computedP : 5,
          'carbs_g': computedC > 0 ? computedC : 30,
          'fats_g': computedF > 0 ? computedF : 5,
          'confidence': 0.1,
          'reasoning': 'AI response could not be parsed. Try taking a clearer photo with better lighting and fewer items.'
        }],
        'meal_type': 'snack',
        'total_calories': computedCal > 0 ? computedCal : 200,
        'total_protein_g': computedP > 0 ? computedP : 5,
        'total_carbs_g': computedC > 0 ? computedC : 30,
        'total_fats_g': computedF > 0 ? computedF : 5,
        'summary': 'Could not read the AI response. Please try again with a clearer photo.'
      };
    } catch (_) {
      return {
        'foods': [{
          'name': 'Unknown',
          'portion_size_g': 100,
          'calories': 200,
          'protein_g': 5,
          'carbs_g': 30,
          'fats_g': 5,
          'confidence': 0.1,
          'reasoning': 'Critical parsing error — please try again'
        }],
        'meal_type': 'snack',
        'total_calories': 200,
        'total_protein_g': 5,
        'total_carbs_g': 30,
        'total_fats_g': 5,
        'summary': 'Error reading AI response. Please try again.'
      };
    }
  }
}
