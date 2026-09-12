/// A single task in the daily planner.
class PlannerTask {
  final int? id;
  final String taskDate;   // 'YYYY-MM-DD'
  final String category;   // 'workout', 'meal_plan', 'general', etc.
  final String title;      // 'Jumping Jacks'
  final String subtitle;   // '1 minute' or '3 sets of 10-12 reps'
  final int sortOrder;
  final bool isDone;

  const PlannerTask({
    this.id,
    required this.taskDate,
    required this.category,
    required this.title,
    this.subtitle = '',
    this.sortOrder = 0,
    this.isDone = false,
  });

  factory PlannerTask.fromMap(Map<String, dynamic> map) {
    return PlannerTask(
      id: map['id'] as int?,
      taskDate: map['task_date'] as String,
      category: map['category'] as String,
      title: map['title'] as String,
      subtitle: (map['subtitle'] as String?) ?? '',
      sortOrder: (map['sort_order'] as int?) ?? 0,
      isDone: ((map['is_done'] as int?) ?? 0) == 1,
    );
  }

  PlannerTask copyWith({
    int? id,
    String? taskDate,
    String? category,
    String? title,
    String? subtitle,
    int? sortOrder,
    bool? isDone,
  }) {
    return PlannerTask(
      id: id ?? this.id,
      taskDate: taskDate ?? this.taskDate,
      category: category ?? this.category,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      sortOrder: sortOrder ?? this.sortOrder,
      isDone: isDone ?? this.isDone,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'task_date': taskDate,
      'category': category,
      'title': title,
      'subtitle': subtitle,
      'sort_order': sortOrder,
      'is_done': isDone ? 1 : 0,
    };
  }

  /// Whether this task represents a section header / block title.
  bool get isSectionHeader {
    return title.startsWith('▸ ') ||
        title.startsWith('🧘') ||
        title.startsWith('💪') ||
        title.startsWith('🔙') ||
        title.startsWith('🦵') ||
        title.startsWith('🔥');
  }

  /// Clean title stripped of block prefix emojis or symbols.
  String get displayTitle {
    if (title.startsWith('▸ ')) {
      return title.substring(2).trim();
    }
    if (isSectionHeader) {
      return title.replaceAll(RegExp(r'^[^\s]+\s'), '').trim();
    }
    return title;
  }
}

/// Category helper — predefined task categories with icons and colors.
enum PlannerCategory {
  workout('Workout', '💪'),
  mealPlan('Meal Plan', '🍽️'),
  general('General', '📋'),
  custom('Custom', '⭐');

  final String label;
  final String emoji;
  const PlannerCategory(this.label, this.emoji);
}