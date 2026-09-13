import 'package:flutter/foundation.dart';
import 'package:eatwise/core/ai/ai_config.dart';
import 'package:eatwise/core/ai/ai_error.dart';
import 'package:eatwise/core/ai/ai_models.dart';
import 'package:eatwise/core/ai/groq_provider.dart';
import 'package:eatwise/core/ai/openrouter_provider.dart';
import 'package:eatwise/features/food_ai/data/gemini_vision_service.dart';
import 'package:eatwise/features/food_ai/data/gemini_chat_service.dart';
import 'package:eatwise/features/food_ai/domain/food_item.dart';
import 'package:eatwise/core/ai/local_food_db.dart';

class _CircuitBreakerState {
  int failureCount = 0;
  DateTime? openUntil;

  bool get isOpen => openUntil != null && DateTime.now().isBefore(openUntil!);

  void recordSuccess() {
    failureCount = 0;
    openUntil = null;
  }

  void recordFailure() {
    failureCount++;
    if (failureCount >= 10) {
      openUntil = DateTime.now().add(const Duration(minutes: 10));
    } else if (failureCount >= 3) {
      openUntil = DateTime.now().add(const Duration(minutes: 2));
    }
  }

  void forceOpen(Duration duration) {
    openUntil = DateTime.now().add(duration);
  }
}

class AiFallbackOrchestrator {
  final Map<String, _CircuitBreakerState> _circuits = {};
  final List<String> _recentChatHistory = [];
  static const int _maxChatHistory = 10;

  GeminiVisionService? _geminiVision;
  GeminiChatService? _geminiChat;
  GroqProvider? _groqText;
  OpenRouterProvider? _openRouter;

  GeminiVisionService get _visionGemini {
    _geminiVision ??= GeminiVisionService(apiKey: AiConfig.geminiApiKey, enableGrounding: AiConfig.enableGeminiGrounding);
    return _geminiVision!;
  }

  GeminiChatService get _chatGemini {
    _geminiChat ??= GeminiChatService(apiKey: AiConfig.geminiApiKey, enableGrounding: AiConfig.enableGeminiGrounding);
    return _geminiChat!;
  }

  GroqProvider get _textGroq {
    _groqText ??= GroqProvider(apiKey: AiConfig.groqApiKey);
    return _groqText!;
  }

  OpenRouterProvider get _routerProvider {
    _openRouter ??= OpenRouterProvider(apiKey: AiConfig.openRouterApiKey);
    return _openRouter!;
  }

  _CircuitBreakerState _breaker(String name) => _circuits.putIfAbsent(name, () => _CircuitBreakerState());

  Future<AnalysisResult> analyzeFood({String? text, Uint8List? image, List<Uint8List>? images}) async {
    MealAnalysis? aiResult;
    String? providerUsed;

    final allImages = <Uint8List>[];
    if (image != null) allImages.add(image);
    if (images != null) allImages.addAll(images);

    if (allImages.isNotEmpty) {
      try {
        aiResult = await _visionGemini.analyzeFoodImages(allImages, text: (text != null && text.isNotEmpty) ? text : null);
        providerUsed = 'Gemini Vision${text != null && text.isNotEmpty ? ' (image + text)' : ''}';
      } catch (e) {
        debugPrint('[Orchestrator] Gemini Vision failed: $e');
      }
    }

    if (aiResult == null && text != null) {
      if (AiConfig.geminiApiKey.isNotEmpty) {
        try {
          final result = await _tryTextProvider(
            'Gemini',
            () => _visionGemini.parseChatMessage(text),
            breaker: _breaker('gemini_food'),
          );
          if (result != null) {
            aiResult = result as MealAnalysis;
            providerUsed = 'Gemini';
          }
        } catch (e) {
          if (kDebugMode) debugPrint('[Orchestrator] Gemini failed: $e');
        }
      }

      if (aiResult == null && AiConfig.isGroqConfigured) {
        try {
          final meal = await _tryTextProvider(
            'Groq',
            () => _textGroq.analyzeFoodText(text),
            breaker: _breaker('groq_food'),
            rethrowRateLimit: true,
          );
          if (meal != null) {
            aiResult = meal as MealAnalysis;
            providerUsed = 'Groq';
          }
        } on RateLimitedException {
          debugPrint('[Orchestrator] Groq rate-limited');
        }
      }

      if (aiResult == null) {
        try {
          final meal = await _tryTextProvider(
            'OpenRouter',
            () => _routerProvider.analyzeFoodText(text),
            breaker: _breaker('openrouter_food'),
            rethrowRateLimit: true,
          );
          if (meal != null) {
            aiResult = meal as MealAnalysis;
            providerUsed = 'OpenRouter';
          }
        } on RateLimitedException {
          debugPrint('[Orchestrator] OpenRouter rate-limited');
        }
      }
    }

    // Local FNRI baseline database fallback — ensures common Filipino meals & sample chips always succeed
    if (aiResult == null && text != null && text.trim().isNotEmpty) {
      final localMatch = _matchLocalBaseline(text);
      if (localMatch != null) {
        aiResult = localMatch;
        providerUsed = 'FNRI Offline Database';
      }
    }

    if (aiResult == null) throw const AllProvidersExhaustedException('food');

    // Return AI result directly — no local DB overrides, no caching
    final finalResult = AnalysisResult(
      items: aiResult.foods.map((f) => ValidatedFoodItem(item: f, status: VerificationStatus.verified, source: providerUsed ?? 'ai')).toList(),
      mealAnalysis: aiResult,
      providerUsed: providerUsed,
    );

    return finalResult;
  }

  Future<ChatResult> sendChatMessage(
    String message, {
    List<({String role, String text})> priorMessages = const [],
  }) async {
    // Build full conversation context from prior messages
    final contextMessage = _buildFullContext(message, priorMessages);

    String? response;
    String? provider;

    // Gemini first if key available
    if (AiConfig.geminiApiKey.isNotEmpty) {
      final geminiText = await _tryTextProvider(
        'Gemini',
        () => _chatGemini.sendMessage(contextMessage),
        breaker: _breaker('gemini_chat'),
      );
      if (geminiText != null) {
        response = geminiText as String;
        provider = 'Gemini';
      }
    }

    if (response == null && AiConfig.isGroqConfigured) {
      final text = await _tryTextProvider(
        'Groq',
        () => _textGroq.chatSendMessage(contextMessage),
        breaker: _breaker('groq_chat'),
      );
      if (text != null) {
        response = text as String;
        provider = 'Groq';
      }
    }

    if (response == null) {
      final text = await _tryTextProvider(
        'OpenRouter',
        () => _routerProvider.sendChatMessage(contextMessage),
        breaker: _breaker('openrouter_chat'),
      );
      if (text != null) {
        response = text as String;
        provider = 'OpenRouter';
      }
    }

    if (response == null) {
      response = _offlineChatResponse(message);
      provider = 'Local Assistant';
    }

    _recentChatHistory.add(message);
    _recentChatHistory.add(response);
    if (_recentChatHistory.length > _maxChatHistory * 2) {
      _recentChatHistory.removeRange(0, _recentChatHistory.length - _maxChatHistory * 2);
    }

    return ChatResult(text: response, providerUsed: provider);
  }

  String _buildFullContext(String message, List<({String role, String text})> priorMessages) {
    if (priorMessages.isEmpty && _recentChatHistory.isEmpty) return message;

    final buf = StringBuffer();
    buf.writeln('You are MacroAI, a Filipino macro-tracking assistant inside the EatWise app.');
    buf.writeln('You have access to the following conversation history.');
    buf.writeln('Use it to give contextually relevant answers. If the user asks about previous food logs,');
    buf.writeln('analyze or refer to the foods mentioned earlier in the conversation.');
    buf.writeln('');

    if (priorMessages.isNotEmpty) {
      for (final msg in priorMessages) {
        final label = msg.role == 'user' ? 'User' : 'You (MacroAI)';
        buf.writeln('$label: ${msg.text}');
        buf.writeln('');
      }
    } else {
      buf.writeln('Previous conversation:');
      for (final line in _recentChatHistory) {
        buf.writeln(line);
      }
      buf.writeln('');
    }

    buf.writeln('--- Current message ---');
    buf.writeln('User: $message');
    return buf.toString();
  }

  Future<dynamic> _tryTextProvider(
    String name,
    Future<dynamic> Function() call, {
    required _CircuitBreakerState breaker,
    bool rethrowRateLimit = false,
  }) async {
    if (breaker.isOpen) {
      if (kDebugMode) debugPrint('[Orchestrator] $name circuit breaker is open, skipping');
      return null;
    }

    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final result = await call();
        breaker.recordSuccess();
        return result;
      } on RateLimitedException {
        if (kDebugMode) debugPrint('[Orchestrator] $name rate-limited (attempt ${attempt + 1})');
        breaker.recordFailure();
        if (rethrowRateLimit) rethrow;
        return null;
      } on AiAuthException {
        if (kDebugMode) debugPrint('[Orchestrator] $name AUTH FAILED — key may be invalid');
        breaker.forceOpen(const Duration(hours: 1));
        return null;
      } on AiContentFilteredException {
        if (kDebugMode) debugPrint('[Orchestrator] $name content filtered');
        return null;
      } catch (e) {
        if (kDebugMode) debugPrint('[Orchestrator] $name error (attempt ${attempt + 1}): $e');
        breaker.recordFailure();
        if (attempt >= 2) return null;
        await Future.delayed(Duration(seconds: attempt + 1));
      }
    }
    return null;
  }

  void invalidateCaches() {
    // No-op: caches removed
  }

  void resetCircuitBreakers() => _circuits.clear();

  void clearChatHistory() => _recentChatHistory.clear();

  void dispose() {
    _geminiVision = null;
    _geminiChat = null;
    _groqText?.dispose();
    _openRouter?.dispose();
  }

  /// Offline local baseline matcher for Filipino dishes and sample inputs
  MealAnalysis? _matchLocalBaseline(String input) {
    final lower = input.toLowerCase().trim();
    if (lower.isEmpty) return null;

    final separators = RegExp(r'\s*(?:&|\+|\band\b|\bwith\b|,|\bplus\b)\s*');
    final segments = lower.split(separators).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) segments.add(lower);

    final matchedFoods = <FoodItem>[];

    for (final seg in segments) {
      double quantity = 1.0;
      String cleanSeg = seg;

      final numMatch = RegExp(r'^(\d+(?:\.\d+)?)\s*(?:pcs?|pieces?|bowl|cups?|serving|servings|plates?|orders?|pc)?\s*(.*)$').firstMatch(cleanSeg);
      if (numMatch != null) {
        final parsed = double.tryParse(numMatch.group(1) ?? '');
        if (parsed != null && parsed > 0) {
          quantity = parsed;
          cleanSeg = (numMatch.group(2) ?? '').trim();
        }
      } else if (cleanSeg.startsWith('half ')) {
        quantity = 0.5;
        cleanSeg = cleanSeg.substring(5).trim();
      }

      if (cleanSeg.isEmpty) cleanSeg = seg;

      VerifiedFoodBaseline? bestMatch;
      int bestScore = 0;

      for (final baseline in verifiedFoodBaselines) {
        final allNames = [baseline.canonicalName.toLowerCase(), ...baseline.searchNames.map((s) => s.toLowerCase())];
        for (final name in allNames) {
          if (cleanSeg == name) {
            if (1000 > bestScore) {
              bestScore = 1000;
              bestMatch = baseline;
            }
          } else if (cleanSeg.contains(name)) {
            final score = name.length * 10;
            if (score > bestScore) {
              bestScore = score;
              bestMatch = baseline;
            }
          } else if (name.contains(cleanSeg) && cleanSeg.length >= 3) {
            final score = cleanSeg.length * 5;
            if (score > bestScore) {
              bestScore = score;
              bestMatch = baseline;
            }
          }
        }
      }

      if (bestMatch != null) {
        final servingGrams = (bestMatch.gramsPerServing != null && bestMatch.gramsPerServing! > 0)
            ? bestMatch.gramsPerServing!
            : 100.0;
        final totalGrams = servingGrams * quantity;
        final cal = (bestMatch.calPer100g * (totalGrams / 100.0)).roundToDouble();
        final p = (bestMatch.proteinPer100g * (totalGrams / 100.0)).roundToDouble();
        final c = (bestMatch.carbsPer100g * (totalGrams / 100.0)).roundToDouble();
        final f = (bestMatch.fatPer100g * (totalGrams / 100.0)).roundToDouble();

        final qStr = quantity == quantity.truncateToDouble() ? quantity.toInt().toString() : quantity.toStringAsFixed(1);
        final portionDesc = '$qStr ${bestMatch.servingDescription ?? "serving"}';

        matchedFoods.add(FoodItem(
          name: bestMatch.canonicalName,
          portionSizeGrams: totalGrams,
          portionDescription: portionDesc,
          calories: cal,
          proteinG: p,
          carbsG: c,
          fatsG: f,
          confidence: 0.95,
          reasoning: 'Calibrated from official FNRI baseline database.',
        ));
      }
    }

    if (matchedFoods.isEmpty) return null;

    final now = DateTime.now();
    final hour = now.hour;
    final mealType = (hour >= 5 && hour < 11)
        ? 'breakfast'
        : (hour >= 11 && hour < 15)
            ? 'lunch'
            : (hour >= 17 && hour < 22)
                ? 'dinner'
                : 'snack';

    return MealAnalysis(
      foods: matchedFoods,
      totalCalories: matchedFoods.fold(0.0, (sum, f) => sum + f.calories),
      totalProtein: matchedFoods.fold(0.0, (sum, f) => sum + f.proteinG),
      totalCarbs: matchedFoods.fold(0.0, (sum, f) => sum + f.carbsG),
      totalFats: matchedFoods.fold(0.0, (sum, f) => sum + f.fatsG),
      summary: input,
      mealType: mealType,
    );
  }

  String _offlineChatResponse(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('hello') || lower.contains('hi') || lower.contains('hey')) {
      return 'Hello! I am your AI Nutrition Coach. You can log meals by typing what you ate (e.g., "Chicken Inasal with sinangag") or snapping a photo!';
    }
    if (lower.contains('macro') || lower.contains('target') || lower.contains('goal') || lower.contains('calorie')) {
      return 'Your daily macro targets are tracked on your Hub screen. For best results, balance lean proteins, smart carbs, and healthy fats across your meals.';
    }
    return 'I am currently operating in offline mode with access to the FNRI Philippine food database. You can log meals by typing dishes like "Sinigang na Baboy & rice" or "2 boiled eggs and 1 pandesal".';
  }
}
