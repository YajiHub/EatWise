import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:eatwise/core/constants/app_colors.dart';
import 'package:eatwise/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:eatwise/features/planner/domain/planner_task.dart';
import 'package:eatwise/features/planner/providers/planner_provider.dart';
import 'package:eatwise/features/planner/data/workout_preset.dart';

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});
  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  final _addTitleCtrl = TextEditingController();
  final _addSubCtrl = TextEditingController();
  String _addCategory = 'general';

  @override
  void dispose() {
    _addTitleCtrl.dispose();
    _addSubCtrl.dispose();
    super.dispose();
  }

  String get _dateStr => DateFormat('yyyy-MM-dd').format(ref.watch(selectedDateProvider));

  @override
  Widget build(BuildContext context) {
    final ps = ref.watch(plannerNotifierProvider);
    final tasks = ps.tasks;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Planner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome_rounded),
            tooltip: 'Routine Presets',
            onPressed: () => _showPresetSelector(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Clear all',
            onPressed: _confirmClear,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: _showAddDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _DateStrip(onSelect: (d) => ref.read(selectedDateProvider.notifier).state = d),
            const Divider(height: 1),
            _QuickHabitBar(
              onAddHabit: (title, subtitle, category) {
                HapticFeedback.lightImpact();
                ref.read(plannerNotifierProvider.notifier).appendQuickHabit(
                      taskDate: _dateStr,
                      title: title,
                      subtitle: subtitle,
                      category: category,
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added: $title'),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            if (tasks.isNotEmpty) ...[
              _ProgressCompletionCard(tasks: tasks, isDark: isDark),
            ],
            Expanded(
              child: ps.loading
                  ? const Center(child: CircularProgressIndicator())
                  : tasks.isEmpty
                      ? _EmptyState(
                          onLoadPreset: () => _showPresetSelector(context),
                          onAdd: _showAddDialog,
                        )
                      : _TaskList(tasks: tasks, onToggle: _onToggle, onDelete: _onDelete),
            ),
          ],
        ),
      ),
    );
  }

  void _onToggle(PlannerTask task) {
    HapticFeedback.selectionClick();
    ref.read(plannerNotifierProvider.notifier).toggle(task.id!, !task.isDone);
  }

  void _onDelete(PlannerTask task) {
    HapticFeedback.mediumImpact();
    ref.read(plannerNotifierProvider.notifier).remove(task.id!);
  }

  void _showPresetSelector(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF0F1420) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Load Routine Preset',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Replace today\'s planner with a calibrated routine template:',
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              _presetOptionTile(
                icon: Icons.fitness_center_rounded,
                iconColor: AppColors.protein,
                title: 'Full Body Home Workout',
                subtitle: '5-block calisthenics: Warmup, Push, Pull, Legs, Core',
                isDark: isDark,
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(plannerNotifierProvider.notifier).loadWorkoutPreset(_dateStr);
                },
              ),
              const SizedBox(height: 10),
              _presetOptionTile(
                icon: Icons.water_drop_rounded,
                iconColor: AppColors.carbs,
                title: 'Hydration & Protein Prep',
                subtitle: '2.5L water milestones, 30g protein targets, healthy snacks',
                isDark: isDark,
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(plannerNotifierProvider.notifier).loadCustomPreset(
                        _dateStr,
                        hydrationProteinPreset(_dateStr),
                      );
                },
              ),
              const SizedBox(height: 10),
              _presetOptionTile(
                icon: Icons.rice_bowl_rounded,
                iconColor: AppColors.primary,
                title: 'Filipino Balanced Diet Reset',
                subtitle: 'Portioned rice, fibrous vegetables, post-meal walk & broth',
                isDark: isDark,
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(plannerNotifierProvider.notifier).loadCustomPreset(
                        _dateStr,
                        filipinoDietResetPreset(_dateStr),
                      );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _presetOptionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141926) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0x18FFFFFF) : Colors.grey.shade300,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? Colors.white38 : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmClear() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all tasks?'),
        content: const Text('Remove all tasks for this day.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(plannerNotifierProvider.notifier).clearDay(_dateStr);
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showAddDialog() {
    _addTitleCtrl.clear();
    _addSubCtrl.clear();
    _addCategory = 'general';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _addTitleCtrl, decoration: const InputDecoration(labelText: 'Task', border: OutlineInputBorder()), autofocus: true),
            const SizedBox(height: 12),
            TextField(controller: _addSubCtrl, decoration: const InputDecoration(labelText: 'Details (optional)', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _addCategory,
              decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'workout', child: Text('💪 Workout')),
                DropdownMenuItem(value: 'meal_plan', child: Text('🍽️ Meal Plan')),
                DropdownMenuItem(value: 'general', child: Text('📋 General')),
              ],
              onChanged: (v) => setState(() => _addCategory = v!),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final title = _addTitleCtrl.text.trim();
              if (title.isEmpty) return;
              Navigator.pop(ctx);
              ref.read(plannerNotifierProvider.notifier).add(taskDate: _dateStr, category: _addCategory, title: title, subtitle: _addSubCtrl.text.trim());
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

// ──────────── QUICK HABIT BAR ────────────

class _QuickHabitBar extends StatelessWidget {
  final void Function(String title, String subtitle, String category) onAddHabit;
  const _QuickHabitBar({required this.onAddHabit});

  static const _habits = [
    ('💧 Drink 500ml Water', 'Hydration boost', 'general'),
    ('🏃 30m Brisk Walk', 'Cardio & blood flow', 'workout'),
    ('🥩 30g Protein Snack', 'Muscle preservation', 'meal_plan'),
    ('🧘 10m Stretching', 'Mobility & recovery', 'workout'),
    ('🚫 Zero Soda Today', 'Sugar control', 'meal_plan'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: _habits.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final h = _habits[i];
          return ActionChip(
            label: Text(h.$1, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
            avatar: const Icon(Icons.add_circle_outline_rounded, size: 14, color: AppColors.primary),
            backgroundColor: isDark ? const Color(0xFF131824) : Colors.grey.shade100,
            side: BorderSide(
              color: isDark ? const Color(0x22FFFFFF) : Colors.grey.shade300,
              width: 0.8,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            onPressed: () => onAddHabit(h.$1, h.$2, h.$3),
          );
        },
      ),
    );
  }
}

// ──────────── PROGRESS COMPLETION CARD ────────────

class _ProgressCompletionCard extends StatelessWidget {
  final List<PlannerTask> tasks;
  final bool isDark;
  const _ProgressCompletionCard({required this.tasks, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final total = tasks.length;
    final done = tasks.where((t) => t.isDone).length;
    final ratio = total == 0 ? 0.0 : done / total;
    final percent = (ratio * 100).toInt();
    final allComplete = total > 0 && done == total;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 4, 14, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101522) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: allComplete
              ? AppColors.primary.withValues(alpha: 0.5)
              : (isDark ? const Color(0x18FFFFFF) : Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                allComplete ? '🔥 ALL TARGETS COMPLETE!' : 'DAILY PROGRESS',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: allComplete ? AppColors.primary : (isDark ? AppColors.textSecondaryDark : Colors.grey.shade600),
                ),
              ),
              const Spacer(),
              Text(
                '$done of $total completed ($percent%)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: allComplete ? AppColors.primary : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: isDark ? const Color(0xFF1B2030) : Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                allComplete ? const Color(0xFF00E676) : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────── DATE STRIP ────────────

class _DateStrip extends ConsumerWidget {
  final ValueChanged<DateTime> onSelect;
  const _DateStrip({required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sel = ref.watch(selectedDateProvider);
    final today = DateTime.now();
    final dates = List.generate(7, (i) => today.subtract(Duration(days: 3 - i)));
    final selStr = DateFormat('yyyy-MM-dd').format(sel);
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        itemCount: 7,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final d = dates[i];
          final active = DateFormat('yyyy-MM-dd').format(d) == selStr;
          final isToday = DateFormat('yyyy-MM-dd').format(d) == todayStr;
          return GestureDetector(
            onTap: () => onSelect(d),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              decoration: BoxDecoration(
                color: active ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: active ? null : Border.all(color: isToday ? AppColors.primary : Colors.grey.shade300, width: isToday ? 2 : 1),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(DateFormat('E').format(d).substring(0, 3).toUpperCase(),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: active ? Colors.white : (isToday ? AppColors.primary : Colors.grey))),
                const SizedBox(height: 2),
                Text('${d.day}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: active ? Colors.white : null)),
              ]),
            ),
          );
        },
      ),
    );
  }
}

// ──────────── EMPTY STATE ────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onLoadPreset;
  final VoidCallback onAdd;
  const _EmptyState({required this.onLoadPreset, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primaryContainer.withValues(alpha: 0.3),
              ),
              child: Icon(Icons.checklist_rounded, size: 52, color: cs.primary),
            ),
            const SizedBox(height: 18),
            Text(
              'No tasks planned yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap a quick habit chip above, load a routine preset, or create your custom task.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade600,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.auto_awesome_rounded, size: 18),
              label: const Text('Load Routine Preset'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: onLoadPreset,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Custom Task'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: onAdd,
            ),
          ],
        ),
      ),
    );
  }
}
class _TaskList extends StatelessWidget {
  final List<PlannerTask> tasks;
  final Function(PlannerTask) onToggle;
  final Function(PlannerTask) onDelete;
  const _TaskList({required this.tasks, required this.onToggle, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<PlannerTask>>{};
    for (final t in tasks) { grouped.putIfAbsent(t.category, () => []).add(t); }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
      itemCount: grouped.entries.length,
      itemBuilder: (_, i) => _CategorySection(
        category: grouped.entries.elementAt(i).key,
        tasks: grouped.entries.elementAt(i).value,
        onToggle: onToggle,
        onDelete: onDelete,
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final String category;
  final List<PlannerTask> tasks;
  final Function(PlannerTask) onToggle;
  final Function(PlannerTask) onDelete;
  const _CategorySection({required this.category, required this.tasks, required this.onToggle, required this.onDelete});

  static final _cats = <String, _CatInfo>{
    'workout': const _CatInfo('Workout', Icons.fitness_center_rounded, AppColors.protein),
    'meal_plan': const _CatInfo('Meal Plan', Icons.restaurant_rounded, AppColors.carbs),
    'general': const _CatInfo('General', Icons.checklist_rounded, AppColors.primary),
  };

  @override
  Widget build(BuildContext context) {
    final info = _cats[category] ?? _CatInfo(category, Icons.star_rounded, AppColors.primary);
    final filtered = tasks.where((t) => t.title.isNotEmpty).toList();
    final done = filtered.where((t) => t.isDone).length;
    final total = filtered.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: info.color.withValues(alpha: 0.08),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(children: [
            Icon(info.icon, size: 18, color: info.color),
            const SizedBox(width: 10),
            Text(info.label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: info.color)),
            const Spacer(),
            if (total > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: info.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                child: Text('$done/$total', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: info.color)),
              ),
          ]),
        ),
        for (int idx = 0; idx < tasks.length; idx++)
          _TaskRow(task: tasks[idx], info: info, onToggle: onToggle, onDelete: onDelete),
        const SizedBox(height: 8),
      ]),
    );
  }
}
class _TaskRow extends StatelessWidget {
  final PlannerTask task;
  final _CatInfo info;
  final Function(PlannerTask) onToggle;
  final Function(PlannerTask) onDelete;
  const _TaskRow({required this.task, required this.info, required this.onToggle, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (task.title.isEmpty) return const SizedBox.shrink();

    if (task.isSectionHeader) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: Row(children: [
          Container(width: 4, height: 18, decoration: BoxDecoration(color: info.color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Expanded(child: Text(task.displayTitle, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: info.color))),
        ]),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onToggle(task),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22, height: 22,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: task.isDone ? info.color : Colors.transparent,
                border: Border.all(color: task.isDone ? info.color : Colors.grey.shade400, width: 2),
              ),
              child: task.isDone ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
            ),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(task.title, style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500,
                  decoration: task.isDone ? TextDecoration.lineThrough : null,
                  color: task.isDone ? Colors.grey : null,
                )),
                if (task.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(task.subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ]),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => onDelete(task),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.close_rounded, size: 18, color: Colors.grey.shade400),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _CatInfo {
  final String label;
  final IconData icon;
  final Color color;
  const _CatInfo(this.label, this.icon, this.color);
}
