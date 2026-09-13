import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:eatwise/core/constants/app_colors.dart';
import 'package:eatwise/core/database/app_database.dart';
import 'package:eatwise/core/ai/local_food_db.dart';
import 'package:eatwise/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:eatwise/features/food_ai/domain/food_item.dart';
import 'package:eatwise/features/food_ai/presentation/widgets/meal_type_selector.dart';

class ManualLogScreen extends ConsumerStatefulWidget {
  const ManualLogScreen({super.key});

  @override
  ConsumerState<ManualLogScreen> createState() => _ManualLogScreenState();
}

class _ManualLogScreenState extends ConsumerState<ManualLogScreen> {
  final _nameCtrl = TextEditingController();
  final _portionCtrl = TextEditingController(text: '100');
  final _portionDescCtrl = TextEditingController(text: '1 serving');
  final _calCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _carbsCtrl = TextEditingController();
  final _fatsCtrl = TextEditingController();
  String _mealType = 'snack';
  final _formKey = GlobalKey<FormState>();
  bool _isUpdatingCalories = false;

  static const _allFoods = verifiedFoodBaselines;

  @override
  void initState() {
    super.initState();
    // Auto-calculate calories when protein/carbs/fats change
    // 1g protein = 4 cal, 1g carbs = 4 cal, 1g fat = 9 cal
    _proteinCtrl.addListener(_recalcCalories);
    _carbsCtrl.addListener(_recalcCalories);
    _fatsCtrl.addListener(_recalcCalories);
  }

  void _recalcCalories() {
    if (_isUpdatingCalories) return;
    _isUpdatingCalories = true;

    final protein = double.tryParse(_proteinCtrl.text) ?? 0;
    final carbs = double.tryParse(_carbsCtrl.text) ?? 0;
    final fats = double.tryParse(_fatsCtrl.text) ?? 0;
    final total = (protein * 4) + (carbs * 4) + (fats * 9);

    if (total > 0) {
      _calCtrl.text = total.toStringAsFixed(0);
    }

    _isUpdatingCalories = false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _portionCtrl.dispose();
    _portionDescCtrl.dispose();
    _calCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatsCtrl.dispose();
    super.dispose();
  }

  void _onFoodSelected(VerifiedFoodBaseline food) {
    _nameCtrl.text = food.canonicalName;
    _portionCtrl.text = food.gramsPerServing?.toStringAsFixed(0) ?? '100';
    _portionDescCtrl.text = food.servingDescription ?? '1 serving';

    final scale = (food.gramsPerServing ?? 100) / 100;
    _calCtrl.text = (food.calPer100g * scale).toStringAsFixed(0);
    _proteinCtrl.text = (food.proteinPer100g * scale).toStringAsFixed(1);
    _carbsCtrl.text = (food.carbsPer100g * scale).toStringAsFixed(1);
    _fatsCtrl.text = (food.fatPer100g * scale).toStringAsFixed(1);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {});
    final name = _nameCtrl.text.trim();
    final portionG = double.tryParse(_portionCtrl.text) ?? 100;
    final cal = double.tryParse(_calCtrl.text) ?? 0;
    final protein = double.tryParse(_proteinCtrl.text) ?? 0;
    final carbs = double.tryParse(_carbsCtrl.text) ?? 0;
    final fats = double.tryParse(_fatsCtrl.text) ?? 0;
    final portionDesc = _portionDescCtrl.text.trim().isEmpty ? '1 serving' : _portionDescCtrl.text.trim();

    final foodItem = FoodItem(
      name: name,
      portionSizeGrams: portionG,
      portionDescription: portionDesc,
      calories: cal,
      proteinG: protein,
      carbsG: carbs,
      fatsG: fats,
      confidence: 1.0,
      reasoning: 'Manual entry',
    );

    final meal = MealAnalysis(
      foods: [foodItem],
      totalCalories: cal,
      totalProtein: protein,
      totalCarbs: carbs,
      totalFats: fats,
      summary: 'Manual: $portionDesc $name = ${cal.toInt()} cal',
      mealType: _mealType,
    );

    try {
      await AppDatabase.insertFoodLog(
        logDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        mealType: _mealType,
        source: 'manual',
        meal: meal,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e'), backgroundColor: Colors.red),
      );
      return;
    }

    ref.read(logVersionProvider.notifier).update((v) => v + 1);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Logged: $portionDesc $name — ${cal.toInt()} cal'), duration: const Duration(seconds: 2)),
    );
    context.pop();
  }

  void _adjustGrams(double delta) {
    final cur = double.tryParse(_portionCtrl.text) ?? 100;
    final updated = (cur + delta).clamp(10.0, 1000.0);
    setState(() {
      _portionCtrl.text = updated.toStringAsFixed(0);
    });
  }

  void _setGrams(double grams) {
    setState(() {
      _portionCtrl.text = grams.toStringAsFixed(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.canvasDark : const Color(0xFFF8F9FA),
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.canvasDark : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MANUAL LOG',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'FOOD DATABASE • CUSTOM MACROS',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Food Item Card ──
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceCard : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? AppColors.surfaceCardBorder : Colors.grey.shade200,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FOOD IDENTIFICATION',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Autocomplete<VerifiedFoodBaseline>(
                      optionsBuilder: (value) {
                        if (value.text.isEmpty) return [];
                        final query = value.text.toLowerCase();
                        return _allFoods.where((f) {
                          return f.canonicalName.toLowerCase().contains(query) ||
                              f.searchNames.any((s) => s.contains(query));
                        }).take(8);
                      },
                      displayStringForOption: (f) => '${f.canonicalName} (${f.calPer100g.toStringAsFixed(0)} cal/100g)',
                      onSelected: _onFoodSelected,
                      fieldViewBuilder: (ctx, ctrl, focusNode, onSubmit) {
                        return TextFormField(
                          controller: ctrl,
                          focusNode: focusNode,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Food or Dish Name',
                            hintText: 'e.g. Chicken Inasal, Brown Rice...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.restaurant_rounded, size: 20),
                            suffixIcon: const Icon(Icons.search_rounded, size: 20),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          autofocus: false,
                        );
                      },
                      optionsViewBuilder: (ctx, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 8,
                            borderRadius: BorderRadius.circular(14),
                            color: isDark ? const Color(0xFF1E2330) : Colors.white,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: 280,
                                maxWidth: MediaQuery.of(context).size.width - 64,
                              ),
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                shrinkWrap: true,
                                itemCount: options.length,
                                separatorBuilder: (_, __) => Divider(
                                  height: 1,
                                  color: isDark ? Colors.white12 : Colors.grey.shade200,
                                ),
                                itemBuilder: (_, i) {
                                  final food = options.elementAt(i);
                                  final scale = (food.gramsPerServing ?? 100) / 100;
                                  final cal = food.calPer100g * scale;
                                  return ListTile(
                                    dense: true,
                                    leading: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${cal.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      food.canonicalName,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'P ${food.proteinPer100g.toStringAsFixed(1)}g • C ${food.carbsPer100g.toStringAsFixed(1)}g • F ${food.fatPer100g.toStringAsFixed(1)}g per 100g',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
                                      ),
                                    ),
                                    onTap: () => onSelected(food),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'PORTION SIZE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton.filledTonal(
                          onPressed: () => _adjustGrams(-25),
                          icon: const Icon(Icons.remove_rounded),
                          tooltip: '-25g',
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _portionCtrl,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Grams',
                              suffixText: 'g',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                            validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Invalid' : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          onPressed: () => _adjustGrams(25),
                          icon: const Icon(Icons.add_rounded),
                          tooltip: '+25g',
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _portionDescCtrl,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Description',
                              hintText: '1 cup, 1 piece',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      children: [50.0, 100.0, 150.0, 200.0, 250.0].map((preset) {
                        return ActionChip(
                          label: Text('${preset.toInt()}g'),
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _setGrams(preset),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Meal Type Card ──
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceCard : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? AppColors.surfaceCardBorder : Colors.grey.shade200,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MEAL CLASSIFICATION',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    MealTypeSelector(
                      selectedMealType: _mealType,
                      onChanged: (v) => setState(() => _mealType = v),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Macro Nutrients Card ──
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceCard : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? AppColors.surfaceCardBorder : Colors.grey.shade200,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'MACRONUTRIENT BREAKDOWN',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          'AUTO-BALANCED (4:4:9)',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _calCtrl,
                            style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary),
                            decoration: InputDecoration(
                              labelText: 'Calories',
                              suffixText: 'kcal',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0 ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _proteinCtrl,
                            style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.protein),
                            decoration: InputDecoration(
                              labelText: 'Protein',
                              suffixText: 'g',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _carbsCtrl,
                            style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.carbs),
                            decoration: InputDecoration(
                              labelText: 'Carbs',
                              suffixText: 'g',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _fatsCtrl,
                            style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.fats),
                            decoration: InputDecoration(
                              labelText: 'Fats',
                              suffixText: 'g',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Log Button ──
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _save,
                  borderRadius: BorderRadius.circular(16),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, Color(0xFF00C853)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded, color: Colors.black, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'LOG TO DAILY FUEL',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
