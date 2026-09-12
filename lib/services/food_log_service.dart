import 'dart:typed_data';
import 'package:eatwise/core/ai/ai_fallback_orchestrator.dart';
import 'package:eatwise/core/ai/ai_models.dart';

class FoodLogService {
  final AiFallbackOrchestrator _orchestrator;

  FoodLogService(this._orchestrator);

  Future<AnalysisResult> analyzeText(String text) async {
    return _orchestrator.analyzeFood(text: text);
  }

  Future<AnalysisResult> analyzeImage(Uint8List imageBytes, {String? fallbackText}) async {
    return _orchestrator.analyzeFood(text: fallbackText, image: imageBytes);
  }

  Future<AnalysisResult> analyzeMultipleImages(List<Uint8List> imageBytesList, {String? fallbackText}) async {
    return _orchestrator.analyzeFood(text: fallbackText, images: imageBytesList);
  }

  void invalidateCache() => _orchestrator.invalidateCaches();
  void dispose() => _orchestrator.dispose();
}
