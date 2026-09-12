class DailySummary {
  final String date;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFats;
  final int mealCount;

  const DailySummary({
    required this.date,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFats,
    required this.mealCount,
  });

  factory DailySummary.fromMap(Map<String, dynamic> map) {
    return DailySummary(
      date: map['log_date'] as String,
      totalCalories: (map['cal'] as num?)?.toDouble() ?? 0,
      totalProtein: (map['p'] as num?)?.toDouble() ?? 0,
      totalCarbs: (map['c'] as num?)?.toDouble() ?? 0,
      totalFats: (map['f'] as num?)?.toDouble() ?? 0,
      mealCount: (map['meal_count'] as num?)?.toInt() ?? 0,
    );
  }
}
