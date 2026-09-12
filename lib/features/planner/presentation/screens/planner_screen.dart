import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:eatwise/core/constants/app_colors.dart';
import 'package:eatwise/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:eatwise/features/planner/domain/planner_task.dart';
import 'package:eatwise/features/planner/providers/planner_provider.dart';

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});
  @override ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  final _addTitleCtrl = TextEditingController();
  final _addSubCtrl = TextEditingController();
  String _addCategory = 'general';

  @override void dispose() {
    _addTitleCtrl.dispose();
    _addSubCtrl.dispose();
    super.dispose();
  }

  String get _dateStr => DateFormat('yyyy-MM-dd').format(ref.watch(selectedDateProvider));

  @override
  Widget build(BuildContext context) {
    final ps = ref.watch(plannerNotifierProvider);
    final tasks = ps.tasks;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Planner'),
        actions: [
          IconButton(icon: const Icon(Icons.fitness_center_rounded), tooltip: 'Load workout', onPressed: _confirmLoadWorkout),
          IconButton(icon: const Icon(Icons.delete_outline_rounded), tooltip: 'Clear all', onPressed: _confirmClear),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        child: Column(children: [
          _DateStrip(onSelect: (d) => ref.read(selectedDateProvider.notifier).state = d),
          const Divider(height: 1),
          Expanded(
            child: ps.loading
                ? const Center(child: CircularProgressIndicator())
                : tasks.isEmpty
                    ? _EmptyState(onLoadWorkout: _confirmLoadWorkout, onAdd: _showAddDialog)
                    : _TaskList(tasks: tasks, onToggle: _onToggle, onDelete: _onDelete),
          ),
        ]),
      ),
    );
  }

  void _onToggle(PlannerTask task) {
    ref.read(plannerNotifierProvider.notifier).toggle(task.id!, !task.isDone);
  }

  void _onDelete(PlannerTask task) {
    ref.read(plannerNotifierProvider.notifier).remove(task.id!);
  }

  void _confirmLoadWorkout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Load Home Workout?'),
        content: const Text('This will add the full 5-block home workout to today.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton.icon(
            icon: const Icon(Icons.fitness_center),
            label: const Text('Load Workout'),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(plannerNotifierProvider.notifier).loadWorkoutPreset(_dateStr);
            },
          ),
        ],
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

// ──────────── WIDGETS ────────────

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

class _EmptyState extends StatelessWidget {
  final VoidCallback onLoadWorkout;
  final VoidCallback onAdd;
  const _EmptyState({required this.onLoadWorkout, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(shape: BoxShape.circle, color: cs.primaryContainer.withValues(alpha: 0.4)),
            child: Icon(Icons.checklist_rounded, size: 56, color: cs.primary)),
          const SizedBox(height: 20),
          Text('No tasks yet', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Plan your meals or load your\nhome workout template.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          const SizedBox(height: 28),
          FilledButton.icon(
            icon: const Icon(Icons.fitness_center_rounded, size: 20),
            label: const Text('Load Home Workout'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
            onPressed: onLoadWorkout,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('Add Custom Task'),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
            onPressed: onAdd,
          ),
        ]),
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
