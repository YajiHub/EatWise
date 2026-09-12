import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:eatwise/features/dashboard/providers/profile_provider.dart';

void main() {
  group('ProfileData calculations', () {
    test('BMR calculation for male (Mifflin-St Jeor)', () {
      const profile = ProfileData(
        gender: 'male',
        age: 30,
        heightCm: 180,
        weightKg: 80,
      );
      expect(profile.bmr, closeTo(1780, 1));
    });

    test('BMR calculation for female (Mifflin-St Jeor)', () {
      const profile = ProfileData(
        gender: 'female',
        age: 30,
        heightCm: 165,
        weightKg: 65,
      );
      expect(profile.bmr, closeTo(1370.25, 1));
    });

    test('TDEE scales correctly with activity level', () {
      const baseProfile = ProfileData(
        gender: 'male',
        age: 30,
        heightCm: 180,
        weightKg: 80,
      );
      
      final sedentary = baseProfile.copyWith(activityLevel: 'sedentary');
      final light = baseProfile.copyWith(activityLevel: 'light');
      final moderate = baseProfile.copyWith(activityLevel: 'moderate');
      final active = baseProfile.copyWith(activityLevel: 'active');
      final veryActive = baseProfile.copyWith(activityLevel: 'very_active');

      expect(sedentary.tdee, closeTo(baseProfile.bmr * 1.2, 1));
      expect(light.tdee, closeTo(baseProfile.bmr * 1.375, 1));
      expect(moderate.tdee, closeTo(baseProfile.bmr * 1.55, 1));
      expect(active.tdee, closeTo(baseProfile.bmr * 1.725, 1));
      expect(veryActive.tdee, closeTo(baseProfile.bmr * 1.9, 1));
    });

    test('Recommended calories for weight loss', () {
      const profile = ProfileData(
        gender: 'male',
        age: 30,
        heightCm: 180,
        weightKg: 80,
        goal: 'lose',
        goalRate: 0.5,
      );
      expect(profile.recommendedCalories, closeTo(2259, 1));
    });

    test('Recommended calories for weight gain', () {
      const profile = ProfileData(
        gender: 'male',
        age: 30,
        heightCm: 180,
        weightKg: 80,
        goal: 'gain',
        goalRate: 0.5,
      );
      expect(profile.recommendedCalories, closeTo(3259, 1));
    });

    test('Recommended calories for maintenance', () {
      const profile = ProfileData(
        gender: 'male',
        age: 30,
        heightCm: 180,
        weightKg: 80,
        goal: 'maintain',
      );
      expect(profile.recommendedCalories, closeTo(2759, 1));
    });
  });

  group('ProfileData BMI and macros', () {
    test('BMI calculation and categories', () {
      // Underweight
      const underweight = ProfileData(weightKg: 50, heightCm: 170);
      expect(underweight.bmi, closeTo(17.3, 0.1));
      expect(underweight.bmiCategory, 'Underweight');
      expect(underweight.bmiColor, Colors.blue);

      // Normal
      const normal = ProfileData(weightKg: 68, heightCm: 170);
      expect(normal.bmi, closeTo(23.5, 0.1));
      expect(normal.bmiCategory, 'Normal');
      expect(normal.bmiColor, Colors.green);

      // Overweight
      const overweight = ProfileData(weightKg: 85, heightCm: 170);
      expect(overweight.bmi, closeTo(29.4, 0.1));
      expect(overweight.bmiCategory, 'Overweight');
      expect(overweight.bmiColor, Colors.orange);

      // Obese
      const obese = ProfileData(weightKg: 100, heightCm: 170);
      expect(obese.bmi, closeTo(34.6, 0.1));
      expect(obese.bmiCategory, 'Obese');
      expect(obese.bmiColor, Colors.red);
    });

    test('Macro targets calculation', () {
      const profile = ProfileData(
        gender: 'male',
        age: 30,
        heightCm: 180,
        weightKg: 80,
        goal: 'maintain',
      );
      final macros = profile.macroTargets;
      expect(macros['calories'], closeTo(2759, 1));
      expect(macros['protein'], closeTo(207, 1));
      expect(macros['carbs'], closeTo(276, 1));
      expect(macros['fats'], closeTo(92, 1));
    });

    test('Weight to goal tracking', () {
      const profile = ProfileData(
        weightKg: 80,
        goalWeightKg: 70,
      );
      expect(profile.weightToGoal, closeTo(10, 0.1));
      expect(profile.weightToGoalLabel, '10.0 kg to lose');

      const gainingProfile = ProfileData(
        weightKg: 70,
        goalWeightKg: 80,
      );
      expect(gainingProfile.weightToGoal, closeTo(-10, 0.1));
      expect(gainingProfile.weightToGoalLabel, '10.0 kg to gain');

      const atGoal = ProfileData(
        weightKg: 70,
        goalWeightKg: 70,
      );
      expect(atGoal.weightToGoal, 0);
      expect(atGoal.weightToGoalLabel, 'At goal weight!');

      const noGoal = ProfileData(weightKg: 70);
      expect(noGoal.weightToGoal, isNull);
      expect(noGoal.weightToGoalLabel, isNull);
    });
  });

  group('ProfileData copyWith', () {
    test('CopyWith preserves unchanged fields', () {
      const original = ProfileData(
        name: 'John',
        age: 30,
        heightCm: 180,
        weightKg: 80,
        goalWeightKg: 70,
      );
      
      final updated = original.copyWith(name: 'Jane', age: 31);
      
      expect(updated.name, 'Jane');
      expect(updated.age, 31);
      expect(updated.heightCm, 180);
      expect(updated.weightKg, 80);
      expect(updated.goalWeightKg, 70);
    });

    test('CopyWith clears optional fields when requested', () {
      const original = ProfileData(
        name: 'John',
        avatarUrl: 'https://example.com/avatar.png',
        goalWeightKg: 70,
        bodyFatPct: 20,
        waistCm: 85,
        hipCm: 100,
      );
      
      final updated = original.copyWith(
        clearAvatar: true,
        clearGoalWeight: true,
        clearBodyFat: true,
        clearWaist: true,
        clearHip: true,
      );
      
      expect(updated.avatarUrl, isNull);
      expect(updated.goalWeightKg, isNull);
      expect(updated.bodyFatPct, isNull);
      expect(updated.waistCm, isNull);
      expect(updated.hipCm, isNull);
    });
  });
}