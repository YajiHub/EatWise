class WeeklyStats {
  final double avgDailyCalories;
  final double avgProtein;
  final double avgCarbs;
  final double avgFats;
  final String? bestDay;
  final double bestDayCalories;
  final int currentStreak;

  const WeeklyStats({
    required this.avgDailyCalories,
    required this.avgProtein,
    required this.avgCarbs,
    required this.avgFats,
    this.bestDay,
    required this.bestDayCalories,
    required this.currentStreak,
  });

  factory WeeklyStats.fromSummaries(List<dynamic> summaries, int streak) {
    if (summaries.isEmpty) {
      return const WeeklyStats(
        avgDailyCalories: 0,
        avgProtein: 0,
        avgCarbs: 0,
        avgFats: 0,
        bestDayCalories: 0,
        currentStreak: 0,
      );
    }
    final count = summaries.length;
    double totalCal = 0, totalP = 0, totalC = 0, totalF = 0;
    double bestCal = 0;
    String? bestDateStr;

    for (final s in summaries) {
      final cal = (s['cal'] as num?)?.toDouble() ?? 0;
      final p = (s['p'] as num?)?.toDouble() ?? 0;
      final c = (s['c'] as num?)?.toDouble() ?? 0;
      final f = (s['f'] as num?)?.toDouble() ?? 0;
      totalCal += cal;
      totalP += p;
      totalC += c;
      totalF += f;
      if (cal > bestCal) {
        bestCal = cal;
        bestDateStr = s['log_date'] as String?;
      }
    }

    String? bestDayLabel;
    if (bestDateStr != null) {
      final d = DateTime.tryParse(bestDateStr);
      if (d != null) {
        const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
        bestDayLabel = days[d.weekday - 1];
      }
    }

    return WeeklyStats(
      avgDailyCalories: totalCal / count,
      avgProtein: totalP / count,
      avgCarbs: totalC / count,
      avgFats: totalF / count,
      bestDay: bestDayLabel,
      bestDayCalories: bestCal,
      currentStreak: streak,
    );
  }
}
