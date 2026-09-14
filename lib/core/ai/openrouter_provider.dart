import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:eatwise/core/ai/ai_config.dart';
import 'package:eatwise/core/ai/ai_error.dart';
import 'package:eatwise/core/ai/ai_json_parser.dart';
import 'package:eatwise/core/ai/ai_prompt_builder.dart';
import 'package:eatwise/features/food_ai/domain/food_item.dart';

class OpenRouterProvider {
  final String apiKey;
  final String model;
  final http.Client _client;

  OpenRouterProvider({required this.apiKey, http.Client? client, String? model})
      : _client = client ?? http.Client(),
        model = model ?? AiConfig.openRouterModel;

  static const _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';

  Future<MealAnalysis> analyzeFoodText(String userMessage) async {
    final content = await _call(
      userMessage: 'Parse this food description into JSON: "$userMessage"',
      temperature: 0.2,
      maxTokens: 2048,
    );
    return _parse(content);
  }

  Future<String> sendChatMessage(String message) async {
    return _call(
      userMessage: message,
      temperature: 0.7,
      maxTokens: 4096,
      systemPrompt: AiPromptBuilder.buildChatSystemPrompt(),
    );
  }

  Future<String> _call({
    required String userMessage,
    required double temperature,
    required int maxTokens,
    String? systemPrompt,
  }) async {
    final prompt = systemPrompt ?? AiPromptBuilder.buildFoodLoggingSystemPrompt();
    final body = jsonEncode({
      'model': model,
      'messages': [
        {'role': 'system', 'content': prompt},
        {'role': 'user', 'content': userMessage},
      ],
      'temperature': temperature,
      'max_tokens': maxTokens,
    });

    debugPrint('[OpenRouter] Sending to $model...');

    try {
      final response = await _client
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
              'HTTP-Referer': 'https://eatwise.app',
              'X-Title': 'EatWise',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('[OpenRouter] Response status: ${response.statusCode}');

      if (response.statusCode == 404) {
        try {
          final err = jsonDecode(response.body);
          final msg = err['error']?['message'] ?? 'Model unavailable or discontinued';
          debugPrint('[OpenRouter] 404 error: $msg');
          throw AiModelUnavailableException('OpenRouter', msg);
        } catch (e) {
          if (e is AiModelUnavailableException) rethrow;
          debugPrint('[OpenRouter] 404 error: ${response.body}');
          throw const AiModelUnavailableException('OpenRouter', 'Model not found on OpenRouter');
        }
      }

      if (response.statusCode == 429) {
        debugPrint('[OpenRouter] Rate limited: ${response.body}');
        throw const RateLimitedException('OpenRouter');
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        debugPrint('[OpenRouter] Auth failed');
        throw const AiAuthException('OpenRouter');
      }
      if (response.statusCode >= 500) {
        debugPrint('[OpenRouter] Server error');
        throw const AiNetworkException('OpenRouter');
      }
      if (response.statusCode == 402) {
        debugPrint('[OpenRouter] No credits');
        throw const AiAuthException('OpenRouter');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final choices = data['choices'] as List<dynamic>;
        if (choices.isNotEmpty) {
          final content = choices[0]['message']['content'] as String;
          debugPrint('[OpenRouter] Success: ${content.length} chars');
          return content;
        }
        debugPrint('[OpenRouter] Empty choices');
      }
      throw const AiNetworkException('OpenRouter');
    } on RateLimitedException {
      rethrow;
    } on AiAuthException {
      rethrow;
    } on AiContentFilteredException {
      rethrow;
    } on AiModelUnavailableException {
      rethrow;
    } catch (e) {
      debugPrint('[OpenRouter] Exception: $e');
      throw const AiNetworkException('OpenRouter');
    }
  }

  MealAnalysis _parse(String rawJson) {
    final parsed = AiJsonParser.parseJsonResponse(rawJson);
    return MealAnalysis.fromJson(parsed);
  }

  String get providerName => 'OpenRouter';
  void dispose() => _client.close();
}
