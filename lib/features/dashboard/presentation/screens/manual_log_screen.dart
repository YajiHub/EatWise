import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('Manual Log')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                    decoration: const InputDecoration(
                      labelText: 'Food Name',
                      hintText: 'Search or type food name...',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.search),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    autofocus: true,
                  );
                },
                optionsViewBuilder: (ctx, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(12),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: 300,
                          maxWidth: MediaQuery.of(context).size.width - 40,
                        ),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          shrinkWrap: true,
                          itemCount: options.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final food = options.elementAt(i);
                            final scale = (food.gramsPerServing ?? 100) / 100;
                            final cal = food.calPer100g * scale;
                            return ListTile(
                              dense: true,
                              leading: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('${cal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                              ),
                              title: Text(food.canonicalName, style: const TextStyle(fontSize: 14)),
                              subtitle: Text('P${food.proteinPer100g.toStringAsFixed(1)} C${food.carbsPer100g.toStringAsFixed(1)} F${food.fatPer100g.toStringAsFixed(1)} per 100g', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                              trailing: food.servingDescription != null
                                  ? Text(food.servingDescription!, style: TextStyle(fontSize: 11, color: Colors.grey.shade500))
                                  : null,
                              onTap: () { onSelected(food); },
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _portionCtrl,
                      decoration: const InputDecoration(labelText: 'Portion (g)', border: OutlineInputBorder()),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                      validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Invalid' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _portionDescCtrl,
                      decoration: const InputDecoration(labelText: 'Description', hintText: '1 piece, 1 cup', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              MealTypeSelector(
                selectedMealType: _mealType,
                onChanged: (v) => setState(() => _mealType = v),
              ),
              const SizedBox(height: 24),
              const Text('Macros', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _calCtrl, decoration: const InputDecoration(labelText: 'Calories', border: OutlineInputBorder()), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0 ? 'Required' : null)),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(controller: _proteinCtrl, decoration: const InputDecoration(labelText: 'Protein (g)', border: OutlineInputBorder()), keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))])),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _carbsCtrl, decoration: const InputDecoration(labelText: 'Carbs (g)', border: OutlineInputBorder()), keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))])),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(controller: _fatsCtrl, decoration: const InputDecoration(labelText: 'Fats (g)', border: OutlineInputBorder()), keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))])),
                ],
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Log Food'),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
