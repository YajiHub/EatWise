import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eatwise/core/database/app_database.dart';

class ProfileData {
  final String name;
  final String? avatarUrl;
  final String gender;
  final int age;
  final double heightCm;
  final double weightKg;
  final String activityLevel;
  final String goal;
  final double goalRate;
  final double? goalWeightKg;
  final double? bodyFatPct;
  final double? waistCm;
  final double? hipCm;
  final DateTime? updatedAt;

  const ProfileData({
    this.name = '',
    this.avatarUrl,
    this.gender = 'male',
    this.age = 25,
    this.heightCm = 170,
    this.weightKg = 70,
    this.activityLevel = 'moderate',
    this.goal = 'maintain',
    this.goalRate = 0.5,
    this.goalWeightKg,
    this.bodyFatPct,
    this.waistCm,
    this.hipCm,
    this.updatedAt,
  });

  ProfileData copyWith({
    String? name,
    String? avatarUrl,
    bool clearAvatar = false,
    String? gender,
    int? age,
    double? heightCm,
    double? weightKg,
    String? activityLevel,
    String? goal,
    double? goalRate,
    double? goalWeightKg,
    bool clearGoalWeight = false,
    double? bodyFatPct,
    bool clearBodyFat = false,
    double? waistCm,
    bool clearWaist = false,
    double? hipCm,
    bool clearHip = false,
    DateTime? updatedAt,
  }) {
    return ProfileData(
      name: name ?? this.name,
      avatarUrl: clearAvatar ? null : (avatarUrl ?? this.avatarUrl),
      gender: gender ?? this.gender,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      activityLevel: activityLevel ?? this.activityLevel,
      goal: goal ?? this.goal,
      goalRate: goalRate ?? this.goalRate,
      goalWeightKg: clearGoalWeight ? null : (goalWeightKg ?? this.goalWeightKg),
      bodyFatPct: clearBodyFat ? null : (bodyFatPct ?? this.bodyFatPct),
      waistCm: clearWaist ? null : (waistCm ?? this.waistCm),
      hipCm: clearHip ? null : (hipCm ?? this.hipCm),
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  double get bmi => weightKg / ((heightCm / 100) * (heightCm / 100));

  String get bmiCategory {
    final bmi = this.bmi;
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Color get bmiColor {
    switch (bmiCategory) {
      case 'Underweight': return Colors.blue;
      case 'Normal': return Colors.green;
      case 'Overweight': return Colors.orange;
      default: return Colors.red;
    }
  }

  double get bmr {
    if (gender == 'male') {
      return (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
    } else {
      return (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
    }
  }

  double get tdee {
    final multiplier = switch (activityLevel) {
      'sedentary' => 1.2,
      'light' => 1.375,
      'moderate' => 1.55,
      'active' => 1.725,
      'very_active' => 1.9,
      _ => 1.55,
    };
    return bmr * multiplier;
  }

  double get recommendedCalories {
    final base = tdee;
    return switch (goal) {
      'lose' => base - (goalRate * 1000),
      'gain' => base + (goalRate * 1000),
      _ => base,
    };
  }

  double get activityMultiplier {
    return switch (activityLevel) {
      'sedentary' => 1.2,
      'light' => 1.375,
      'moderate' => 1.55,
      'active' => 1.725,
      'very_active' => 1.9,
      _ => 1.55,
    };
  }

  String get macroSplit {
    final cal = recommendedCalories;
    final protein = (cal * 0.3 / 4).round();
    final carbs = (cal * 0.4 / 4).round();
    final fats = (cal * 0.3 / 9).round();
    return '$protein g protein / $carbs g carbs / $fats g fats';
  }

  Map<String, double> get macroTargets {
    final cal = recommendedCalories;
    return {
      'calories': cal,
      'protein': (cal * 0.3 / 4),
      'carbs': (cal * 0.4 / 4),
      'fats': (cal * 0.3 / 9),
    };
  }

  double? get weightToGoal {
    if (goalWeightKg == null) return null;
    return weightKg - goalWeightKg!;
  }

  String? get weightToGoalLabel {
    final diff = weightToGoal;
    if (diff == null) return null;
    if (diff > 0) return '${diff.toStringAsFixed(1)} kg to lose';
    if (diff < 0) return '${(-diff).toStringAsFixed(1)} kg to gain';
    return 'At goal weight!';
  }
}

class ProfileNotifier extends StateNotifier<ProfileData> {
  ProfileNotifier() : super(const ProfileData()) {
    load();
  }

  Future<void> load() async {
    final name = await AppDatabase.getSetting('profile_name');
    final avatarUrl = await AppDatabase.getSetting('profile_avatar_url');
    final gender = await AppDatabase.getSetting('profile_gender');
    final age = await AppDatabase.getIntSetting('profile_age', 25);
    final heightCm = await AppDatabase.getNumericSetting('profile_height_cm', 170);
    final weightKg = await AppDatabase.getNumericSetting('profile_weight_kg', 70);
    final activityLevel = await AppDatabase.getSetting('profile_activity_level');
    final goal = await AppDatabase.getSetting('profile_goal');
    final goalRate = await AppDatabase.getNumericSetting('profile_goal_rate', 0.5);
    final goalWeightKg = await AppDatabase.getNumericSetting('profile_goal_weight_kg', 0);
    final bodyFatPct = await AppDatabase.getNumericSetting('profile_body_fat_pct', 0);
    final waistCm = await AppDatabase.getNumericSetting('profile_waist_cm', 0);
    final hipCm = await AppDatabase.getNumericSetting('profile_hip_cm', 0);
    final updatedAtStr = await AppDatabase.getSetting('profile_updated_at');

    state = ProfileData(
      name: name ?? '',
      avatarUrl: avatarUrl,
      gender: gender ?? 'male',
      age: age,
      heightCm: heightCm > 0 ? heightCm : 170,
      weightKg: weightKg > 0 ? weightKg : 70,
      activityLevel: activityLevel ?? 'moderate',
      goal: goal ?? 'maintain',
      goalRate: goalRate,
      goalWeightKg: goalWeightKg > 0 ? goalWeightKg : null,
      bodyFatPct: bodyFatPct > 0 ? bodyFatPct : null,
      waistCm: waistCm > 0 ? waistCm : null,
      hipCm: hipCm > 0 ? hipCm : null,
      updatedAt: updatedAtStr != null ? DateTime.tryParse(updatedAtStr) : null,
    );
  }

  Future<void> save() async {
    await AppDatabase.setSetting('profile_name', state.name);
    await AppDatabase.setSetting('profile_avatar_url', state.avatarUrl ?? '');
    await AppDatabase.setSetting('profile_gender', state.gender);
    await AppDatabase.setSetting('profile_age', state.age.toString());
    await AppDatabase.setSetting('profile_height_cm', state.heightCm.toString());
    await AppDatabase.setSetting('profile_weight_kg', state.weightKg.toString());
    await AppDatabase.setSetting('profile_activity_level', state.activityLevel);
    await AppDatabase.setSetting('profile_goal', state.goal);
    await AppDatabase.setSetting('profile_goal_rate', state.goalRate.toString());
    if (state.goalWeightKg != null) {
      await AppDatabase.setSetting('profile_goal_weight_kg', state.goalWeightKg!.toString());
    } else {
      await AppDatabase.setSetting('profile_goal_weight_kg', '');
    }
    if (state.bodyFatPct != null) {
      await AppDatabase.setSetting('profile_body_fat_pct', state.bodyFatPct!.toString());
    } else {
      await AppDatabase.setSetting('profile_body_fat_pct', '');
    }
    if (state.waistCm != null) {
      await AppDatabase.setSetting('profile_waist_cm', state.waistCm!.toString());
    } else {
      await AppDatabase.setSetting('profile_waist_cm', '');
    }
    if (state.hipCm != null) {
      await AppDatabase.setSetting('profile_hip_cm', state.hipCm!.toString());
    } else {
      await AppDatabase.setSetting('profile_hip_cm', '');
    }
    await AppDatabase.setSetting('profile_updated_at', state.updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String());
  }

  void update({
    String? name,
    String? avatarUrl,
    bool clearAvatar = false,
    String? gender,
    int? age,
    double? heightCm,
    double? weightKg,
    String? activityLevel,
    String? goal,
    double? goalRate,
    double? goalWeightKg,
    bool clearGoalWeight = false,
    double? bodyFatPct,
    bool clearBodyFat = false,
    double? waistCm,
    bool clearWaist = false,
    double? hipCm,
    bool clearHip = false,
  }) {
    state = state.copyWith(
      name: name,
      avatarUrl: avatarUrl,
      clearAvatar: clearAvatar,
      gender: gender,
      age: age,
      heightCm: heightCm,
      weightKg: weightKg,
      activityLevel: activityLevel,
      goal: goal,
      goalRate: goalRate,
      goalWeightKg: goalWeightKg,
      clearGoalWeight: clearGoalWeight,
      bodyFatPct: bodyFatPct,
      clearBodyFat: clearBodyFat,
      waistCm: waistCm,
      clearWaist: clearWaist,
      hipCm: hipCm,
      clearHip: clearHip,
    );
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileData>((ref) {
  final notifier = ProfileNotifier();
  Future.microtask(() => notifier.load());
  return notifier;
});
