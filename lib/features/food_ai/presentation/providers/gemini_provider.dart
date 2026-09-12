import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eatwise/core/ai/ai_fallback_orchestrator.dart';
import 'package:eatwise/services/food_log_service.dart';
import 'package:eatwise/services/ask_ai_service.dart';

final aiOrchestratorProvider = Provider<AiFallbackOrchestrator>((ref) {
  final orchestrator = AiFallbackOrchestrator();
  ref.onDispose(() => orchestrator.dispose());
  return orchestrator;
});

final foodLogServiceProvider = Provider<FoodLogService>((ref) {
  final orchestrator = ref.watch(aiOrchestratorProvider);
  return FoodLogService(orchestrator);
});

final askAiServiceProvider = Provider<AskAiService>((ref) {
  final orchestrator = ref.watch(aiOrchestratorProvider);
  return AskAiService(orchestrator);
});
