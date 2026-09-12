import 'package:eatwise/features/food_ai/domain/food_item.dart';

enum VerificationStatus { verified, estimated }

class ValidatedFoodItem {
  final FoodItem item;
  final VerificationStatus status;
  final String source;

  const ValidatedFoodItem({
    required this.item,
    required this.status,
    this.source = 'ai',
  });
}

class AnalysisResult {
  final List<ValidatedFoodItem> items;
  final MealAnalysis mealAnalysis;
  final String? providerUsed;

  const AnalysisResult({
    required this.items,
    required this.mealAnalysis,
    this.providerUsed,
  });
}

class ChatResult {
  final String text;
  final String? providerUsed;

  const ChatResult({required this.text, this.providerUsed});
}

enum AiCapability { vision, text }

class AiProviderInfo {
  final String name;
  final Set<AiCapability> capabilities;

  const AiProviderInfo({required this.name, required this.capabilities});
}
