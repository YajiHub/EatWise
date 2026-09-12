class MonthlyStats {
  final double totalCalories;
  final double avgDailyCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFats;
  final int loggedDaysCount;

  const MonthlyStats({
    required this.totalCalories,
    required this.avgDailyCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFats,
    required this.loggedDaysCount,
  });

  factory MonthlyStats.fromTotals(Map<String, double> totals) {
    final cal = totals['calories'] ?? 0;
    final days = (totals['logged_days'] ?? 0).toInt();
    return MonthlyStats(
      totalCalories: cal,
      avgDailyCalories: days > 0 ? cal / days : 0,
      totalProtein: totals['protein'] ?? 0,
      totalCarbs: totals['carbs'] ?? 0,
      totalFats: totals['fats'] ?? 0,
      loggedDaysCount: days,
    );
  }
}
