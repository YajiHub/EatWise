import 'package:flutter/foundation.dart';
import 'package:eatwise/core/ai/ai_config.dart';
import 'package:eatwise/core/ai/ai_error.dart';
import 'package:eatwise/core/ai/ai_models.dart';
import 'package:eatwise/core/ai/groq_provider.dart';
import 'package:eatwise/core/ai/openrouter_provider.dart';
import 'package:eatwise/features/food_ai/data/gemini_vision_service.dart';
import 'package:eatwise/features/food_ai/data/gemini_chat_service.dart';
import 'package:eatwise/features/food_ai/domain/food_item.dart';

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
      // Gemini first — has broader training data including Filipino branded products
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
      } on RateLimitedException {
        if (kDebugMode) debugPrint('[Orchestrator] Gemini rate-limited');
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

    // Gemini first — better conversational quality with broader training data
    final geminiText = await _tryTextProvider(
      'Gemini',
      () => _chatGemini.sendMessage(contextMessage),
      breaker: _breaker('gemini_chat'),
    );
    if (geminiText != null) {
      response = geminiText as String;
      provider = 'Gemini';
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

    if (response == null) throw const AllProvidersExhaustedException('chat');

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
      } on Exception catch (e) {
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
}
