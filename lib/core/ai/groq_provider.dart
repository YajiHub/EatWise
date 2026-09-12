import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:eatwise/core/ai/ai_config.dart';
import 'package:eatwise/core/ai/ai_error.dart';
import 'package:eatwise/core/ai/ai_json_parser.dart';
import 'package:eatwise/core/ai/ai_prompt_builder.dart';
import 'package:eatwise/features/food_ai/domain/food_item.dart';

class GroqProvider {
  final String apiKey;
  final String model;
  final http.Client _client;

  GroqProvider({required this.apiKey, http.Client? client, String? model})
      : _client = client ?? http.Client(),
        model = model ?? AiConfig.groqModel;

  static const _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  Future<MealAnalysis> analyzeFoodText(String userMessage) async {
    final content = await _call(
      systemPrompt: AiPromptBuilder.buildFoodLoggingSystemPrompt(),
      userMessage: 'Parse this food description into JSON: "$userMessage"',
      temperature: 0.2,
      maxTokens: 2048,
      requireJson: true,
    );
    return _parse(content);
  }

  Future<String> chatSendMessage(String message) async {
    return _call(
      systemPrompt: AiPromptBuilder.buildChatSystemPrompt(),
      userMessage: message,
      temperature: 0.7,
      maxTokens: 4096,
      requireJson: false,
    );
  }

  Future<String> _call({
    required String systemPrompt,
    required String userMessage,
    required double temperature,
    required int maxTokens,
    required bool requireJson,
  }) async {
    final bodyMap = <String, dynamic>{
      'model': model,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userMessage},
      ],
      'temperature': temperature,
      'max_completion_tokens': maxTokens,
    };

    if (requireJson) {
      bodyMap['response_format'] = {'type': 'json_object'};
    }

    final body = jsonEncode(bodyMap);

    debugPrint('[Groq] Sending to $model (json=$requireJson)...');

    try {
      final response = await _client
          .post(Uri.parse(_baseUrl), headers: {'Authorization': 'Bearer $apiKey', 'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 30));

      debugPrint('[Groq] Response status: ${response.statusCode}');

      if (response.statusCode == 429) {
        debugPrint('[Groq] Rate limited');
        throw RateLimitedException('Groq');
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        debugPrint('[Groq] Auth failed — check API key');
        throw AiAuthException('Groq');
      }
      if (response.statusCode >= 500) {
        debugPrint('[Groq] Server error');
        throw AiNetworkException('Groq');
      }
      if (response.statusCode == 400) {
        final err = jsonDecode(response.body);
        final msg = err['error']?['message'] ?? '';
        debugPrint('[Groq] 400 error: $msg');
        if (msg.contains('safety') || msg.contains('content')) throw AiContentFilteredException('Groq');
        throw AiNetworkException('Groq');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final choices = data['choices'] as List<dynamic>;
        if (choices.isNotEmpty) {
          final content = choices[0]['message']['content'] as String;
          debugPrint('[Groq] Success: ${content.length} chars');
          return content;
        }
        debugPrint('[Groq] Empty choices array');
      }
      throw AiNetworkException('Groq');
    } on RateLimitedException {
      rethrow;
    } on AiAuthException {
      rethrow;
    } on AiContentFilteredException {
      rethrow;
    } catch (e) {
      debugPrint('[Groq] Exception: $e');
      throw AiNetworkException('Groq');
    }
  }

  MealAnalysis _parse(String rawJson) {
    final parsed = AiJsonParser.parseJsonResponse(rawJson);
    return MealAnalysis.fromJson(parsed);
  }

  String get providerName => 'Groq';
  void dispose() => _client.close();
}
