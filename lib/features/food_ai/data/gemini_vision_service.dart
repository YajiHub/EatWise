import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:eatwise/core/ai/ai_config.dart';
import 'package:eatwise/core/ai/ai_error.dart';
import 'package:eatwise/core/ai/image_quality_checker.dart';
import 'package:eatwise/core/ai/ai_json_parser.dart';
import 'package:eatwise/core/ai/ai_prompt_builder.dart';
import 'package:eatwise/core/errors/failures.dart';
import 'package:eatwise/features/food_ai/domain/food_item.dart';

class GeminiVisionService {
  final String _apiKey;

  // Primary model — gemini-2.5-flash
  late final GenerativeModel _visionModel;
  late final GenerativeModel _textModel;

  // Fallback model — gemini-1.5-flash (more stable, less likely to 503)
  late final GenerativeModel _visionModelFallback;
  late final GenerativeModel _textModelFallback;

  GeminiVisionService({required String apiKey, bool enableGrounding = false})
      : _apiKey = apiKey {
    _visionModel = _buildModel(AiConfig.geminiModel, AiPromptBuilder.buildVisionSystemPrompt());
    _textModel = _buildModel(AiConfig.geminiModel, AiPromptBuilder.buildFoodLoggingSystemPrompt());
    _visionModelFallback = _buildModel(AiConfig.geminiFallbackModel, AiPromptBuilder.buildVisionSystemPrompt());
    _textModelFallback = _buildModel(AiConfig.geminiFallbackModel, AiPromptBuilder.buildFoodLoggingSystemPrompt());
  }

  GenerativeModel _buildModel(String modelName, String systemPrompt) {
    return GenerativeModel(
      model: modelName,
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.1,
        topP: 0.8,
        topK: 40,
        maxOutputTokens: 8192,
      ),
      systemInstruction: Content.system(systemPrompt),
    );
  }

  Future<MealAnalysis> analyzeFoodImage(Uint8List imageBytes) async {
    return _analyzeWithVision([imageBytes], text: null);
  }

  Future<MealAnalysis> analyzeFoodImages(List<Uint8List> imageBytesList, {String? text}) async {
    return _analyzeWithVision(imageBytesList, text: text);
  }

  Future<MealAnalysis> analyzeFoodImageWithText(Uint8List imageBytes, {String? text}) async {
    return _analyzeWithVision([imageBytes], text: text);
  }

  Future<MealAnalysis> _analyzeWithVision(List<Uint8List> imageBytesList, {String? text}) async {
    try {
      for (final imageBytes in imageBytesList) {
        final qualityChecker = ImageQualityChecker();
        final qualityResult = qualityChecker.checkImageBytes(imageBytes);
        if (kDebugMode) debugPrint('[GeminiVision] Image quality: ${(qualityResult.quality * 100).toStringAsFixed(1)}%');
        if (qualityResult.shouldReject) {
          throw AIProcessingFailure(
            message: 'Image quality too poor: ${qualityResult.issues.join(", ")}. ${qualityResult.recommendation}',
          );
        }
      }

      final parts = <Part>[
        TextPart(text != null && text.isNotEmpty
            ? 'The user sent ${imageBytesList.length} photo(s) of their food and described it as: "$text". '
              'IDENTIFY every visible food item across ALL photos. '
              'If you see a packaged product with a nutrition label, READ the label and use those exact values. '
              'Estimate portions visually (1 fist = ~200g rice, 1 palm = ~100g meat, 1 egg = ~50g). '
              'List each food item separately. Return ONLY raw JSON, no markdown.'
            : 'IDENTIFY all food items visible in these ${imageBytesList.length} photo(s). '
              'If you see a packaged product with a readable nutrition label, extract and use those exact values. '
              'For unpackaged food, estimate portions visually using these references: '
              '1 fist-sized mound = ~200g rice, 1 palm-sized piece = ~100g meat/fish, 1 egg = ~50g, 1 bowl of soup = ~250g. '
              'List each distinct food as a separate item. Return ONLY raw JSON, no markdown.'),
      ];

      for (final bytes in imageBytesList) {
        parts.add(DataPart('image/jpeg', bytes));
      }

      final responseText = await _generateWithRetry(
        primaryModel: _visionModel,
        fallbackModel: _visionModelFallback,
        content: Content.multi(parts),
        label: 'Vision${imageBytesList.length > 1 ? ' (${imageBytesList.length} images)' : ''}',
      );

      return _parseMealAnalysis(responseText);
    } on RateLimitedException {
      rethrow;
    } on AIProcessingFailure {
      rethrow;
    } catch (e) {
      throw AIProcessingFailure(message: 'MacroAI vision error: $e');
    }
  }

  Future<MealAnalysis> parseChatMessage(String userMessage) async {
    try {
      final responseText = await _generateWithRetry(
        primaryModel: _textModel,
        fallbackModel: _textModelFallback,
        content: Content.text(
          'Parse this food description and return accurate nutritional data as JSON: "$userMessage"\n\n'
          'Use your knowledge of USDA, FNRI, and Filipino branded products. '
          'For branded products (Dutch Mill, Nescafe, Selecta, Magnolia, San Miguel, Coca-Cola, etc.), '
          'use the ACTUAL published label nutrition facts — NOT estimates. '
          'If the user specifies a brand + product name, assume they want the exact known values. '
          'For example, "dutchmill delight 400ml" = 79 cal/100ml, 316 cal per 400ml bottle.',
        ),
        label: 'Text',
      );

      return _parseMealAnalysis(responseText);
    } on RateLimitedException {
      rethrow;
    } on AIProcessingFailure {
      rethrow;
    } catch (e) {
      throw AIProcessingFailure(message: 'MacroAI text error: $e');
    }
  }

  /// Generates content with automatic retry and fallback to a secondary model.
  /// Handles 503 (overloaded) by retrying up to 2 times then switching model.
  Future<String> _generateWithRetry({
    required GenerativeModel primaryModel,
    required GenerativeModel fallbackModel,
    required Content content,
    required String label,
  }) async {
    // Try primary model with 2 retries for 503
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        if (kDebugMode) debugPrint('[GeminiVision] $label attempt ${attempt + 1} (primary model)');
        final response = await primaryModel.generateContent([content]);
        final text = response.text;
        if (text != null && text.isNotEmpty) {
          debugPrint('[GeminiVision] ✓ $label success on attempt ${attempt + 1}');
          return text;
        }
      } catch (e) {
        final errStr = e.toString().toLowerCase();
        final isRateLimited = errStr.contains('quota exceeded') ||
            errStr.contains('rate limit') ||
            errStr.contains('resource_exhausted') ||
            errStr.contains('429');
        final is503 = errStr.contains('503') || errStr.contains('overloaded') || errStr.contains('unavailable');
        debugPrint('[GeminiVision] ✗ $label attempt ${attempt + 1} failed: $e (is503=$is503)');
        // This key has no Gemini capacity left; hand off to another provider.
        if (isRateLimited) break;
        if (!is503 || attempt >= 1) break; // Only retry on 503, max 2 attempts
        await Future.delayed(const Duration(seconds: 3));
      }
    }

    // Try fallback model
    try {
      debugPrint('[GeminiVision] $label trying fallback model (${AiConfig.geminiFallbackModel})');
      final response = await fallbackModel.generateContent([content]);
      final text = response.text;
      if (text != null && text.isNotEmpty) {
        debugPrint('[GeminiVision] ✓ $label fallback model succeeded');
        return text;
      }
    } catch (e) {
      debugPrint('[GeminiVision] ✗ $label fallback model also failed: $e');
    }

    throw const AIProcessingFailure(
      message: 'MacroAI is currently overloaded. Please try again in a moment.',
    );
  }

  MealAnalysis _parseMealAnalysis(String rawJson) {
    try {
      if (kDebugMode) debugPrint('[GeminiVision] Parsing response (${rawJson.length} chars)');
      final parsed = AiJsonParser.parseJsonResponse(rawJson);
      debugPrint('[GeminiVision] ✓ Successfully parsed response');
      return MealAnalysis.fromJson(parsed);
    } on AIProcessingFailure {
      rethrow;
    } catch (e) {
      debugPrint('[GeminiVision] ❌ Parse error: $e');
      throw const AIProcessingFailure(
        message: 'MacroAI response was malformed. Please try again.',
      );
    }
  }
}
