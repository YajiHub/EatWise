import 'package:eatwise/core/ai/ai_fallback_orchestrator.dart';
import 'package:eatwise/core/ai/ai_models.dart';

class AskAiService {
  final AiFallbackOrchestrator _orchestrator;

  AskAiService(this._orchestrator);

  Future<ChatResult> sendMessage(String message) async {
    return _orchestrator.sendChatMessage(message);
  }

  Future<ChatResult> sendMessageWithHistory(
    String message,
    List<({String role, String text})> priorMessages,
  ) async {
    return _orchestrator.sendChatMessage(message, priorMessages: priorMessages);
  }

  void invalidateCache() => _orchestrator.invalidateCaches();
  void dispose() => _orchestrator.dispose();
}
