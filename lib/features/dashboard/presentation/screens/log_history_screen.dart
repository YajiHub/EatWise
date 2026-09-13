import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:eatwise/core/constants/app_colors.dart';
import 'package:eatwise/core/database/app_database.dart';
import 'package:eatwise/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:eatwise/features/dashboard/presentation/widgets/monthly_calendar_grid.dart';
import 'package:eatwise/features/food_ai/domain/food_item.dart';
import 'package:eatwise/features/food_ai/presentation/widgets/meal_type_selector.dart';

class LogHistoryScreen extends ConsumerStatefulWidget {
  const LogHistoryScreen({super.key});
  @override
  ConsumerState<LogHistoryScreen> createState() => _LogHistoryScreenState();
}

class _LogHistoryScreenState extends ConsumerState<LogHistoryScreen> {
  List<Map<String, dynamic>> _logs = [];
  Map<String, double> _totals = {};
  DateTime _date = DateTime.now();
  bool _loading = true;
  bool _showCalendar = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final ds = DateFormat('yyyy-MM-dd').format(_date);
    final logs = await AppDatabase.getLogsForDate(ds);
    final totals = await AppDatabase.getDailyTotals(ds);
    if (!mounted) return;
    setState(() { _logs = logs; _totals = totals; _loading = false; });
  }

  Future<void> _deleteLog(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete entry?'),
        content: const Text('This food entry will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await AppDatabase.deleteLog(id);
    ref.read(logVersionProvider.notifier).update((v) => v + 1);
    _load();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Entry deleted'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  IconData _mealIcon(String type) => MealTypeSelector.mealTypeIcon(type);
  String _mealLabel(String type) => MealTypeSelector.mealTypeLabel(type);
  Color _mealColor(String type) {
    return switch (type) {
      'breakfast' => Colors.orange,
      'lunch' => Colors.amber.shade700,
      'dinner' => Colors.indigo,
      _ => Colors.teal,
    };
  }

  List<String> _parseFoodNames(String rawJson) {
    try {
      final data = jsonDecode(rawJson) as Map<String, dynamic>;
      final foods = data['foods'] as List<dynamic>?;
      if (foods == null || foods.isEmpty) return [];
      return foods.map((f) {
        final m = f as Map<String, dynamic>;
        return (m['name'] as String? ?? '').trim();
      }).where((n) => n.isNotEmpty).toList();
    } catch (_) {
      return [];
    }
  }

  void _editLog(Map<String, dynamic> log) {
    final id = log['id'] as int;
    final rawJson = log['raw_json'] as String? ?? '{}';
    MealAnalysis? meal;
    try {
      meal = MealAnalysis.fromJson(jsonDecode(rawJson) as Map<String, dynamic>);
    } catch (_) {}

    if (meal == null || meal.foods.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _EditLogSheet(
        meal: meal!,
        onSave: (updated) async {
          final newJson = jsonEncode(updated.toJson());
          await AppDatabase.updateFoodLog(id,
            mealType: updated.mealType,
            rawJson: newJson,
            totalCalories: updated.totalCalories,
            totalProtein: updated.totalProtein,
            totalCarbs: updated.totalCarbs,
            totalFats: updated.totalFats,
            summary: updated.summary,
          );
          ref.read(logVersionProvider.notifier).update((v) => v + 1);
          _load();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(logVersionProvider, (_, __) => _load());

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.canvasDark : const Color(0xFFF8F9FA),
      extendBody: true,
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
              child: const Icon(Icons.history_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LOG HISTORY',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'DAILY FUEL BREAKDOWN',
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
        actions: [
          IconButton(
            icon: Icon(_showCalendar ? Icons.calendar_view_day_rounded : Icons.calendar_month_rounded),
            tooltip: _showCalendar ? 'Day view' : 'Calendar view',
            onPressed: () => setState(() => _showCalendar = !_showCalendar),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          if (!_showCalendar) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  DateFormat('MMMM yyyy').format(_date),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            _DayPicker(
              selected: _date,
              onSelect: (d) {
                setState(() => _date = d);
                _load();
              },
            ),
          ] else ...[
            MonthlyCalendarGrid(
              selectedDate: _date,
              onSelectDate: (d) {
                setState(() => _date = d);
                _load();
              },
            ),
          ],
          if (!_loading)
            _DailySummaryCard(
              totals: _totals,
              logs: _logs,
              date: _date,
              compact: _showCalendar,
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _logs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.restaurant_menu, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Builder(
                              builder: (_) {
                                final now = DateTime.now();
                                final isToday = _date.year == now.year && _date.month == now.month && _date.day == now.day;
                                return Text(
                                  isToday ? 'No meals logged today' : 'No meals logged on ${DateFormat('MMMM d, yyyy').format(_date)}',
                                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                                );
                              },
                            ),
                            const SizedBox(height: 4),
                            const Text('Use Scan or Chat to log food', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: _logs.length + 1,
                        itemBuilder: (_, i) {
                          if (i == 0) {
                            final now = DateTime.now();
                            final isToday = _date.year == now.year && _date.month == now.month && _date.day == now.day;
                            final dateTitle = isToday ? 'Meal log' : 'Meal log • ${DateFormat('EEE, MMM d').format(_date)}';
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(dateTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                  if (_logs.isNotEmpty)
                                    Text('${_logs.length} ${_logs.length == 1 ? 'entry' : 'entries'}',
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            );
                          }
                          i -= 1;
                          final l = _logs[i];
                          final id = l['id'] as int;
                          final mealType = l['meal_type'] as String? ?? 'snack';
                          final source = l['source'] as String? ?? 'chat';
                          final rawJson = l['raw_json'] as String? ?? '{}';
                          final imagePath = l['image_path'] as String? ?? '';
                          final foods = _parseFoodNames(rawJson);
                          final timeStr = _formatTime(l['created_at'] as String? ?? '');
                          final cal = (l['total_calories'] as num?)?.toDouble() ?? 0;
                          final protein = (l['total_protein_g'] as num?)?.toDouble() ?? 0;
                          final carbs = (l['total_carbs_g'] as num?)?.toDouble() ?? 0;
                          final fats = (l['total_fats_g'] as num?)?.toDouble() ?? 0;
                          final summary = l['summary'] as String? ?? '';

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (imagePath.isNotEmpty)
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.file(
                                            File(imagePath),
                                            width: 44,
                                            height: 44,
                                            fit: BoxFit.cover,
                                            cacheWidth: 88,
                                            cacheHeight: 88,
                                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                          ),
                                        ),
                                      if (imagePath.isNotEmpty) const SizedBox(width: 10),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: _mealColor(mealType).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(_mealIcon(mealType), size: 20, color: _mealColor(mealType)),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              foods.isNotEmpty
                                                  ? foods.first
                                                  : (summary.isNotEmpty ? summary : _mealLabel(mealType)),
                                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                            ),
                                            if (foods.isNotEmpty)
                                              Text(
                                                foods.join(' · '),
                                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            if (timeStr.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 2),
                                                child: Text(timeStr,
                                                    style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.grey.shade500)),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withValues(alpha: 0.08),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '${cal.toStringAsFixed(0)} cal',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              GestureDetector(
                                                onTap: () => _editLog(l),
                                                child: Icon(Icons.edit_outlined, size: 18, color: Colors.blue.shade300),
                                              ),
                                              const SizedBox(width: 8),
                                              GestureDetector(
                                                onTap: () => _deleteLog(id),
                                                child: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade300),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (summary.isNotEmpty && foods.isEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(summary, style: TextStyle(fontSize: 12, color: Colors.grey.shade500), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  ],
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      _macroChip('P ${protein.toStringAsFixed(0)}g', AppColors.protein),
                                      const SizedBox(width: 6),
                                      _macroChip('C ${carbs.toStringAsFixed(0)}g', AppColors.carbs),
                                      const SizedBox(width: 6),
                                      _macroChip('F ${fats.toStringAsFixed(0)}g', AppColors.fats),
                                      const Spacer(),
                                      _sourceBadge(source, imagePath.isNotEmpty),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _macroChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _sourceBadge(String source, bool hasImage) {
    final (icon, label, color) = switch (source) {
      'photo' => (Icons.camera_alt, 'Photo', Colors.purple),
      'chat' => (Icons.chat_bubble_outline, 'Chat', Colors.blue),
      'manual' => (Icons.create, 'Manual', Colors.teal),
      _ => (Icons.restaurant, source, Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(5)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasImage) ...[
            const Icon(Icons.image, size: 10, color: Colors.purple),
            const SizedBox(width: 2),
          ],
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 2),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  String _formatTime(String created) {
    final dt = DateTime.tryParse(created);
    if (dt == null) return '';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ── Edit Log Bottom Sheet ──

class _EditLogSheet extends StatefulWidget {
  final MealAnalysis meal;
  final ValueChanged<MealAnalysis> onSave;

  const _EditLogSheet({required this.meal, required this.onSave});

  @override
  State<_EditLogSheet> createState() => _EditLogSheetState();
}

class _EditLogSheetState extends State<_EditLogSheet> {
  late String _mealType;
  late List<_FoodEditRow> _foods;

  @override
  void initState() {
    super.initState();
    _mealType = widget.meal.mealType;
    _foods = widget.meal.foods.map((f) => _FoodEditRow.fromFoodItem(f)).toList();
  }

  void _save() {
    FocusScope.of(context).unfocus();
    final items = _foods.map((f) => f.toFoodItem()).toList();
    final updated = MealAnalysis(
      foods: items,
      totalCalories: items.fold(0.0, (s, f) => s + f.calories),
      totalProtein: items.fold(0.0, (s, f) => s + f.proteinG),
      totalCarbs: items.fold(0.0, (s, f) => s + f.carbsG),
      totalFats: items.fold(0.0, (s, f) => s + f.fatsG),
      summary: widget.meal.summary,
      mealType: _mealType,
    );
    widget.onSave(updated);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text('Edit Meal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            MealTypeSelector(
              selectedMealType: _mealType,
              onChanged: (v) => setState(() => _mealType = v),
            ),
            const SizedBox(height: 12),
            const Text('Food Items', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._foods.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: f.build(context, () => setState(() {})),
            )),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Save Changes'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _FoodEditRow {
  late TextEditingController nameCtrl;
  late TextEditingController portionCtrl;
  late TextEditingController calCtrl;
  late TextEditingController proteinCtrl;
  late TextEditingController carbsCtrl;
  late TextEditingController fatsCtrl;

  _FoodEditRow.fromFoodItem(FoodItem item) {
    nameCtrl = TextEditingController(text: item.name);
    portionCtrl = TextEditingController(text: item.portionSizeGrams.toStringAsFixed(0));
    calCtrl = TextEditingController(text: item.calories.toStringAsFixed(0));
    proteinCtrl = TextEditingController(text: item.proteinG.toStringAsFixed(1));
    carbsCtrl = TextEditingController(text: item.carbsG.toStringAsFixed(1));
    fatsCtrl = TextEditingController(text: item.fatsG.toStringAsFixed(1));
  }

  void dispose() {
    nameCtrl.dispose();
    portionCtrl.dispose();
    calCtrl.dispose();
    proteinCtrl.dispose();
    carbsCtrl.dispose();
    fatsCtrl.dispose();
  }

  void _recalcCalories() {
    final p = double.tryParse(proteinCtrl.text) ?? 0;
    final c = double.tryParse(carbsCtrl.text) ?? 0;
    final f = double.tryParse(fatsCtrl.text) ?? 0;
    final cal = (p * 4) + (c * 4) + (f * 9);
    if (cal > 0) calCtrl.text = cal.toStringAsFixed(0);
  }

  FoodItem toFoodItem() => FoodItem(
    name: nameCtrl.text.trim(),
    portionSizeGrams: double.tryParse(portionCtrl.text) ?? 0,
    portionDescription: '',
    calories: double.tryParse(calCtrl.text) ?? 0,
    proteinG: double.tryParse(proteinCtrl.text) ?? 0,
    carbsG: double.tryParse(carbsCtrl.text) ?? 0,
    fatsG: double.tryParse(fatsCtrl.text) ?? 0,
    confidence: 1.0,
    reasoning: 'Edited in history',
  );

  Widget build(BuildContext context, VoidCallback onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Name', isDense: true, border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
          style: const TextStyle(fontSize: 13),
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: portionCtrl,
                decoration: const InputDecoration(labelText: 'Portion (g)', isDense: true, border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                style: const TextStyle(fontSize: 13),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                onChanged: (_) => onChanged(),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: TextFormField(
                controller: calCtrl,
                decoration: const InputDecoration(labelText: 'Cal', isDense: true, border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                style: const TextStyle(fontSize: 13),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => onChanged(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: proteinCtrl,
                decoration: const InputDecoration(labelText: 'Protein (g)', isDense: true, border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                style: const TextStyle(fontSize: 13),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                onChanged: (_) { _recalcCalories(); onChanged(); },
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: TextFormField(
                controller: carbsCtrl,
                decoration: const InputDecoration(labelText: 'Carbs (g)', isDense: true, border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                style: const TextStyle(fontSize: 13),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                onChanged: (_) { _recalcCalories(); onChanged(); },
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: TextFormField(
                controller: fatsCtrl,
                decoration: const InputDecoration(labelText: 'Fats (g)', isDense: true, border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                style: const TextStyle(fontSize: 13),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                onChanged: (_) { _recalcCalories(); onChanged(); },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DayPicker extends StatelessWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;

  const _DayPicker({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    // Start with today so the active day is visible without any scrolling.
    final days = List.generate(
        21, (i) => DateTime(today.year, today.month, today.day - i));
    final selDay = DateTime(selected.year, selected.month, selected.day);
    final todayNorm = DateTime(today.year, today.month, today.day);
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return SizedBox(
      height: 74,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: days.length,
        itemBuilder: (_, i) {
          final d = days[i];
          final isSelected = d == selDay;
          final isToday = d == todayNorm;
          return GestureDetector(
            onTap: () => onSelect(d),
            child: Container(
              width: 46,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(labels[d.weekday - 1],
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : Colors.grey.shade600)),
                  const SizedBox(height: 2),
                  Text('${d.day}',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : null)),
                  if (isToday && !isSelected)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                          color: AppColors.primary, shape: BoxShape.circle),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DailySummaryCard extends StatelessWidget {
  final Map<String, double> totals;
  final List<Map<String, dynamic>> logs;
  final DateTime date;
  final bool compact;

  const _DailySummaryCard({
    required this.totals,
    required this.logs,
    required this.date,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final totalCal = totals['calories'] ?? 0;
    final maxCal = logs.fold<double>(0, (m, l) {
      final c = (l['total_calories'] as num?)?.toDouble() ?? 0;
      return c > m ? c : m;
    });
    final today = DateTime.now();
    final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
    final dateLabel = isToday ? 'today' : DateFormat('MMM d').format(date);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: compact ? 10 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  totalCal.toStringAsFixed(0),
                  style: TextStyle(
                      fontSize: compact ? 26 : 34,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('kcal $dateLabel',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                ),
                const Spacer(),
                _miniMacro('P', totals['protein'] ?? 0, AppColors.protein),
                const SizedBox(width: 10),
                _miniMacro('C', totals['carbs'] ?? 0, AppColors.carbs),
                const SizedBox(width: 10),
                _miniMacro('F', totals['fats'] ?? 0, AppColors.fats),
              ],
            ),
            if (!compact) ...[
              const SizedBox(height: 14),
              Text('Intake rhythm',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600)),
              const SizedBox(height: 6),
              SizedBox(
                height: 56,
                child: logs.isEmpty
                    ? Center(
                        child: Text('No meals logged yet',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade500)))
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: logs.map((l) {
                          final c =
                              (l['total_calories'] as num?)?.toDouble() ?? 0;
                          final h = maxCal > 0 ? (c / maxCal) * 44 : 0.0;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: Container(
                                height: c > 0 ? h.clamp(4.0, 44.0) : 2.0,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                      alpha: c > 0 ? 0.85 : 0.2),
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4)),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _miniMacro(String label, double value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('${value.toStringAsFixed(0)}g',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        Text(label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
      ],
    );
  }
}
