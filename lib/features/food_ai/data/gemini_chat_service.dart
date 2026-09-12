import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:eatwise/core/ai/ai_config.dart';
import 'package:eatwise/core/ai/ai_prompt_builder.dart';

class GeminiChatService {
  final ChatSession _chat;

  GeminiChatService({required String apiKey, bool enableGrounding = false})
      : _chat = GenerativeModel(
          model: AiConfig.geminiModel,
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            temperature: 0.7,
            topP: 0.9,
            topK: 40,
            maxOutputTokens: 4096,
          ),
          systemInstruction: Content.system(AiPromptBuilder.buildChatSystemPrompt()),
          // Note: Google Search grounding requires google_generative_ai >= 0.6
          // Accuracy is improved via system prompts instructing USDA/FNRI knowledge
        ).startChat(history: [
          Content.model([TextPart('Hi! I am MacroAI, your nutrition assistant. Tell me what you ate and I will log it, or ask me anything about nutrition.')]),
        ]);

  Future<String> sendMessage(String message) async {
    final response = await _chat.sendMessage(Content.text(message));
    return response.text ?? 'I am not sure how to answer that. Could you rephrase?';
  }
}
