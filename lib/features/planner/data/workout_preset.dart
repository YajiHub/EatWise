/// Pre-built home workout template.
/// Each entry is a raw map matching the planner_tasks table columns.
List<Map<String, dynamic>> homeWorkoutPreset(String date) {
  int o = 0;
  Map<String, dynamic> t(String title, String subtitle) => {
    'task_date': date,
    'category': 'workout',
    'title': title,
    'subtitle': subtitle,
    'sort_order': o++,
    'is_done': 0,
  };

  return [
    t('🧘 Block 1: Warmup (5 min)', ''),
    t('Jumping Jacks', '1 minute'),
    t('Arm Circles', '1 minute'),
    t('Arm Scissors', '1 minute'),
    t('Bodyweight Squats (Slow)', '15 reps'),

    t('💪 Block 2: Push (Chest & Triceps)', '3 sets, pick your level'),
    t('L1: Incline Push-ups / L2: Standard / L3: Decline', '3 sets × 8-12 reps'),
    t('Tricep Dips', '3 sets × 8-12 reps'),

    t('🔙 Block 3: Pull (Back & Biceps)', '3 sets each'),
    t('Bent-Over Rows', '3 sets × 10-12 (backpack/weights)'),
    t('Bicep Curls', '3 sets × 10-12 (backpack/weights)'),

    t('🦵 Block 4: Leg Builders', '3 sets × 10-12 each'),
    t('Bulgarian Split Squats', '3 sets × 10-12 (switch legs)'),
    t('Squats with backpack/weights', '3 sets × 10-12'),

    t('🔥 Block 5: Core Finisher', 'Circuit × 3 rounds, rest 1 min'),
    t('Lying Leg Raises', '15 reps'),
    t('Russian Twists', '20 reps'),
    t('Plank', '45-60 seconds'),
  ];
}