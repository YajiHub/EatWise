import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eatwise/core/database/app_database.dart';
import 'package:eatwise/core/constants/app_colors.dart';
import 'package:eatwise/features/dashboard/providers/profile_provider.dart';
import 'package:eatwise/features/dashboard/providers/weight_provider.dart';
import 'package:eatwise/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:eatwise/core/theme/theme_mode_provider.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _goalWeightCtrl = TextEditingController();
  final _bodyFatCtrl = TextEditingController();
  final _waistCtrl = TextEditingController();
  final _hipCtrl = TextEditingController();
  final _picker = ImagePicker();
  bool _fieldsPopulated = false;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(profileProvider.notifier).load();
      if (!mounted) return;
      final profile = ref.read(profileProvider);
      _nameCtrl.text = profile.name;
      _ageCtrl.text = profile.age.toString();
      _heightCtrl.text = profile.heightCm.toStringAsFixed(0);
      _weightCtrl.text = profile.weightKg.toStringAsFixed(1);
      _goalWeightCtrl.text = profile.goalWeightKg?.toStringAsFixed(1) ?? '';
      _bodyFatCtrl.text = profile.bodyFatPct?.toStringAsFixed(1) ?? '';
      _waistCtrl.text = profile.waistCm?.toStringAsFixed(1) ?? '';
      _hipCtrl.text = profile.hipCm?.toStringAsFixed(1) ?? '';
      _avatarUrl = profile.avatarUrl;
      _fieldsPopulated = true;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _goalWeightCtrl.dispose();
    _bodyFatCtrl.dispose();
    _waistCtrl.dispose();
    _hipCtrl.dispose();
    super.dispose();
  }

  void _recalc() {
    final age = int.tryParse(_ageCtrl.text);
    final height = double.tryParse(_heightCtrl.text);
    final weight = double.tryParse(_weightCtrl.text);
    final goalWeight = double.tryParse(_goalWeightCtrl.text);
    final bodyFat = double.tryParse(_bodyFatCtrl.text);
    final waist = double.tryParse(_waistCtrl.text);
    final hip = double.tryParse(_hipCtrl.text);
    
    ref.read(profileProvider.notifier).update(
      name: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
      age: age,
      heightCm: height,
      weightKg: weight,
      goalWeightKg: goalWeight,
      clearGoalWeight: goalWeight == null && _goalWeightCtrl.text.isNotEmpty,
      bodyFatPct: bodyFat,
      clearBodyFat: bodyFat == null && _bodyFatCtrl.text.isNotEmpty,
      waistCm: waist,
      clearWaist: waist == null && _waistCtrl.text.isNotEmpty,
      hipCm: hip,
      clearHip: hip == null && _hipCtrl.text.isNotEmpty,
    );
  }

  Future<void> _pickAvatar() async {
    // Use image picker to select from camera or gallery
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 512,
      maxHeight: 512,
    );
    
    if (pickedFile != null) {
      setState(() {
        // Convert XFile to displayable URL/path
        _avatarUrl = pickedFile.path;
      });
      // TODO: Implement image upload to server
      // For now, show snackbar with file path info
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Avatar selected: ${pickedFile.name}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final weightAsync = ref.watch(latestWeightProvider);
    final latestWeight = weightAsync.valueOrNull;

    // Pre-fill weight from latest entry on first load
    if (!_fieldsPopulated && latestWeight != null && _weightCtrl.text.isEmpty) {
      _weightCtrl.text = latestWeight.weightKg.toStringAsFixed(1);
    }

    return Scaffold(
      extendBody: true,
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),

            _profileHeader(profile),

            // ── Settings entry ──
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                leading: const Icon(Icons.tune_outlined, color: AppColors.primary),
                title: const Text('App preferences', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Theme, fasting window & notifications'),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () => context.push('/settings'),
              ),
            ),

            // ── Profile Card ──
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.badge_outlined, size: 20, color: AppColors.primary),
                        const SizedBox(width: 8),
                        const Text('Personal stats', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Name
                    Row(
                      children: [
                        const Text('Name', style: TextStyle(color: Colors.grey, fontSize: 14)),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 200,
                          child: TextField(
                            controller: _nameCtrl,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            decoration: const InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              hintText: 'Your name',
                            ),
                            onChanged: (_) => _recalc(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Gender
                    Row(
                      children: [
                        const Text('Gender', style: TextStyle(color: Colors.grey, fontSize: 14)),
                        const SizedBox(width: 12),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'male', label: Text('Male')),
                            ButtonSegment(value: 'female', label: Text('Female')),
                          ],
                          selected: {profile.gender},
                          onSelectionChanged: (v) {
                            ref.read(profileProvider.notifier).update(gender: v.first);
                          },
                          style: SegmentedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Age
                    Row(
                      children: [
                        const Text('Age', style: TextStyle(color: Colors.grey, fontSize: 14)),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: _ageCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            decoration: const InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              suffixText: 'yrs',
                            ),
                            onChanged: (_) => _recalc(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Height
                    Row(
                      children: [
                        const Text('Height', style: TextStyle(color: Colors.grey, fontSize: 14)),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 100,
                          child: TextField(
                            controller: _heightCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            decoration: const InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              suffixText: 'cm',
                            ),
                            onChanged: (_) => _recalc(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Weight
                    Row(
                      children: [
                        const Text('Weight', style: TextStyle(color: Colors.grey, fontSize: 14)),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 100,
                          child: TextField(
                            controller: _weightCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            decoration: const InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              suffixText: 'kg',
                            ),
                            onChanged: (_) => _recalc(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Activity & Goals Card ──
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.directions_run_outlined, size: 20, color: AppColors.primary),
                        const SizedBox(width: 8),
                        const Text('Activity level & goal', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Activity Level
                    DropdownButtonFormField<String>(
                      value: profile.activityLevel,
                      decoration: const InputDecoration(
                        labelText: 'Activity Level',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'sedentary', child: Text('Sedentary (desk job)')),
                        DropdownMenuItem(value: 'light', child: Text('Light (1-2 days/week)')),
                        DropdownMenuItem(value: 'moderate', child: Text('Moderate (3-5 days/week)')),
                        DropdownMenuItem(value: 'active', child: Text('Active (6-7 days/week)')),
                        DropdownMenuItem(value: 'very_active', child: Text('Very Active (2x/day)')),
                      ],
                      onChanged: (v) {
                        if (v != null) ref.read(profileProvider.notifier).update(activityLevel: v);
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _activityDescription(profile.activityLevel),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),

                    // Goal
                    DropdownButtonFormField<String>(
                      value: profile.goal,
                      decoration: const InputDecoration(
                        labelText: 'Goal',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'lose', child: Text('Lose Weight')),
                        DropdownMenuItem(value: 'maintain', child: Text('Maintain Weight')),
                        DropdownMenuItem(value: 'gain', child: Text('Gain Weight')),
                      ],
                      onChanged: (v) {
                        if (v != null) ref.read(profileProvider.notifier).update(goal: v);
                      },
                    ),
                    if (profile.goal != 'maintain') ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<double>(
                        value: profile.goalRate,
                        decoration: InputDecoration(
                          labelText: profile.goal == 'lose' ? 'Weight Loss Rate' : 'Weight Gain Rate',
                          border: const OutlineInputBorder(),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: [
                          DropdownMenuItem(value: 0.25, child: Text('0.25 kg / week (gentle)')),
                          DropdownMenuItem(value: 0.5, child: Text('0.5 kg / week (moderate)')),
                        ],
                        onChanged: (v) {
                          if (v != null) ref.read(profileProvider.notifier).update(goalRate: v);
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Results Card ──
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.local_fire_department_outlined, size: 20, color: AppColors.primary),
                        const SizedBox(width: 8),
                        const Text('Health & insights', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your maintenance — the energy you burn each day.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 12),
                    _resultRow('BMR (at rest)', '${profile.bmr.toStringAsFixed(0)} kcal/day'),
                    _resultRow('Activity Multiplier', '× ${profile.activityMultiplier.toStringAsFixed(2)}'),
                    _resultRow('TDEE (maintenance)', '${profile.tdee.toStringAsFixed(0)} kcal/day',
                        valueColor: AppColors.primary),
                    const Divider(height: 20),
                    _resultRow('Recommended Daily', '${profile.recommendedCalories.toStringAsFixed(0)} kcal',
                        valueColor: AppColors.primary),
                    const Divider(height: 20),
                    _resultRow('BMI', '${profile.bmi.toStringAsFixed(1)} (${profile.bmiCategory})',
                        valueColor: profile.bmiColor),
                    if (profile.weightToGoalLabel != null)
                      _resultRow('Goal Progress', profile.weightToGoalLabel!,
                          valueColor: AppColors.primary),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.pie_chart_outline, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Suggested macros (40/30/30): ${profile.macroSplit}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Apply Button ──
            _appSettingsCard(context, ref),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: FilledButton.icon(
                onPressed: () => _applyTargets(context, ref, profile),
                icon: const Icon(Icons.sync, size: 20),
                label: const Text('Sync to Dashboard'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            // ── Save Button ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: OutlinedButton.icon(
                onPressed: () => _saveProfile(ref, profile),
                icon: const Icon(Icons.save_outlined, size: 20),
                label: const Text('Save Profile'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _profileHeader(ProfileData profile) {
    final displayAvatar = _avatarUrl ?? profile.avatarUrl;
    final displayName = _nameCtrl.text.isNotEmpty ? _nameCtrl.text : (profile.name.isNotEmpty ? profile.name : 'Your profile');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceCard : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.surfaceCardBorder : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            GestureDetector(
              onTap: _pickAvatar,
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.6), width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: isDark ? AppColors.surfaceContainerHigh : AppColors.primary.withValues(alpha: 0.15),
                      backgroundImage: displayAvatar != null && displayAvatar.isNotEmpty 
                          ? (displayAvatar.startsWith('http') || displayAvatar.startsWith('https')) ? NetworkImage(displayAvatar) : FileImage(File(displayAvatar)) 
                          : null,
                      child: displayAvatar == null || displayAvatar.isEmpty
                          ? const Icon(Icons.person_rounded, color: AppColors.primary, size: 34)
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: isDark ? AppColors.surfaceCard : Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt, size: 12, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${profile.age} yrs • ${profile.heightCm.toStringAsFixed(0)} cm • ${profile.weightKg.toStringAsFixed(1)} kg',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: profile.bmiColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: profile.bmiColor.withValues(alpha: 0.4), width: 0.8),
                        ),
                        child: Text(
                          'BMI: ${profile.bmi.toStringAsFixed(1)} (${profile.bmiCategory})',
                          style: TextStyle(
                            fontSize: 10.5, 
                            fontWeight: FontWeight.w700, 
                            color: profile.bmiColor,
                          ),
                        ),
                      ),
                      if (profile.weightToGoalLabel != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 0.8),
                          ),
                          child: Text(
                            profile.weightToGoalLabel!,
                            style: const TextStyle(
                              fontSize: 10.5, 
                              fontWeight: FontWeight.w700, 
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _appSettingsCard(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final fastingEnabled = ref.watch(fastingEnabledProvider).valueOrNull ?? false;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          const ListTile(
            leading: Icon(Icons.settings_outlined, color: AppColors.primary),
            title: Text('App settings', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('Appearance and routine preferences'),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Dark mode'),
            subtitle: const Text('Use the darker EatWise color scheme'),
            value: mode == ThemeMode.dark,
            onChanged: (enabled) => ref.read(themeModeProvider.notifier).set(
                  enabled ? ThemeMode.dark : ThemeMode.light,
                ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          SwitchListTile(
            secondary: const Icon(Icons.nights_stay_outlined, color: AppColors.fasting),
            title: const Text('Fasting window'),
            subtitle: Text(fastingEnabled ? 'Shown on your Home dashboard' : 'Turn on to track your eating window'),
            value: fastingEnabled,
            onChanged: (enabled) async {
              await AppDatabase.setSetting('fasting_enabled', enabled ? 'true' : 'false');
              ref.invalidate(fastingEnabledProvider);
            },
          ),
          ListTile(
            leading: const Icon(Icons.tune_outlined, color: AppColors.primary),
            title: const Text('More preferences'),
            subtitle: const Text('Fasting schedule and notifications'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings'),
          ),
        ],
      ),
    );
  }

  Widget _resultRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: valueColor)),
        ],
      ),
    );
  }

  String _activityDescription(String level) {
    return switch (level) {
      'sedentary' => 'Little or no exercise, desk job',
      'light' => 'Light exercise 1-2 days per week',
      'moderate' => 'Moderate exercise 3-5 days per week',
      'active' => 'Daily exercise or intense 3-4 days/week',
      'very_active' => 'Intense exercise daily or physical job',
      _ => '',
    };
  }

  Future<void> _applyTargets(BuildContext context, WidgetRef ref, ProfileData profile) async {
    final cal = profile.recommendedCalories.round().clamp(800, 5000);
    final proteinG = (cal * 0.3 / 4).round();
    final carbsG = (cal * 0.4 / 4).round();
    final fatsG = (cal * 0.3 / 9).round();

    await AppDatabase.setSetting('target_calories', cal.toString());
    await AppDatabase.setSetting('target_protein', proteinG.toString());
    await AppDatabase.setSetting('target_carbs', carbsG.toString());
    await AppDatabase.setSetting('target_fats', fatsG.toString());

    ref.read(targetCaloriesProvider.notifier).state = cal.toDouble();
    ref.read(targetProteinProvider.notifier).state = proteinG.toDouble();
    ref.read(targetCarbsProvider.notifier).state = carbsG.toDouble();
    ref.read(targetFatsProvider.notifier).state = fatsG.toDouble();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Targets updated: $cal cal/day')),
      );
    }
  }

  Future<void> _saveProfile(WidgetRef ref, ProfileData profile) async {
    // Sync the local avatar URL to the provider before saving
    ref.read(profileProvider.notifier).update(avatarUrl: _avatarUrl);
    await ref.read(profileProvider.notifier).save();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved')),
      );
    }
  }
}
