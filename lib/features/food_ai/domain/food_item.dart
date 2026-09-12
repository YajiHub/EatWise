import 'package:equatable/equatable.dart';

class FoodItem extends Equatable {
  final String name;
  final String nameTagalog;
  final double portionSizeGrams;
  final String portionDescription;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatsG;
  final double confidence;
  final String reasoning;

  const FoodItem({
    required this.name,
    this.nameTagalog = '',
    required this.portionSizeGrams,
    required this.portionDescription,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatsG,
    this.confidence = 0.0,
    this.reasoning = '',
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      name: json['name'] as String? ?? '',
      nameTagalog: json['name_tagalog'] as String? ?? '',
      portionSizeGrams: (json['portion_size_g'] as num?)?.toDouble() ?? 0,
      portionDescription: json['portion_description'] as String? ?? '',
      calories: (json['calories'] as num?)?.toDouble() ?? 0,
      proteinG: (json['protein_g'] as num?)?.toDouble() ?? 0,
      carbsG: (json['carbs_g'] as num?)?.toDouble() ?? 0,
      fatsG: (json['fats_g'] as num?)?.toDouble() ?? 0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      reasoning: json['reasoning'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'name_tagalog': nameTagalog,
        'portion_size_g': portionSizeGrams,
        'portion_description': portionDescription,
        'calories': calories,
        'protein_g': proteinG,
        'carbs_g': carbsG,
        'fats_g': fatsG,
        'confidence': confidence,
        'reasoning': reasoning,
      };

  FoodItem copyWith({
    String? name,
    String? nameTagalog,
    double? portionSizeGrams,
    String? portionDescription,
    double? calories,
    double? proteinG,
    double? carbsG,
    double? fatsG,
    double? confidence,
    String? reasoning,
  }) {
    return FoodItem(
      name: name ?? this.name,
      nameTagalog: nameTagalog ?? this.nameTagalog,
      portionSizeGrams: portionSizeGrams ?? this.portionSizeGrams,
      portionDescription: portionDescription ?? this.portionDescription,
      calories: calories ?? this.calories,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatsG: fatsG ?? this.fatsG,
      confidence: confidence ?? this.confidence,
      reasoning: reasoning ?? this.reasoning,
    );
  }

  @override
  List<Object?> get props => [
        name,
        nameTagalog,
        portionSizeGrams,
        portionDescription,
        calories,
        proteinG,
        carbsG,
        fatsG,
        confidence,
        reasoning,
      ];
}

class MealAnalysis {
  final List<FoodItem> foods;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFats;
  final String summary;
  final String mealType;

  const MealAnalysis({
    required this.foods,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFats,
    required this.summary,
    this.mealType = 'snack',
  });

  factory MealAnalysis.fromJson(Map<String, dynamic> json) {
    final foodsList = (json['foods'] as List<dynamic>?)
            ?.map((f) => FoodItem.fromJson(f as Map<String, dynamic>))
            .toList() ??
        [];
    return MealAnalysis(
      foods: foodsList,
      totalCalories: (json['total_calories'] as num?)?.toDouble() ?? 0,
      totalProtein: (json['total_protein_g'] as num?)?.toDouble() ?? 0,
      totalCarbs: (json['total_carbs_g'] as num?)?.toDouble() ?? 0,
      totalFats: (json['total_fats_g'] as num?)?.toDouble() ?? 0,
      summary: json['summary'] as String? ?? '',
      mealType: json['meal_type'] as String? ?? 'snack',
    );
  }

  Map<String, dynamic> toJson() => {
        'foods': foods.map((f) => f.toJson()).toList(),
        'total_calories': totalCalories,
        'total_protein_g': totalProtein,
        'total_carbs_g': totalCarbs,
        'total_fats_g': totalFats,
        'summary': summary,
        'meal_type': mealType,
      };

  MealAnalysis copyWith({
    List<FoodItem>? foods,
    String? summary,
    String? mealType,
  }) {
    final items = foods ?? this.foods;
    return MealAnalysis(
      foods: items,
      totalCalories: items.fold<double>(0, (sum, f) => sum + f.calories),
      totalProtein: items.fold<double>(0, (sum, f) => sum + f.proteinG),
      totalCarbs: items.fold<double>(0, (sum, f) => sum + f.carbsG),
      totalFats: items.fold<double>(0, (sum, f) => sum + f.fatsG),
      summary: summary ?? this.summary,
      mealType: mealType ?? this.mealType,
    );
  }
}
