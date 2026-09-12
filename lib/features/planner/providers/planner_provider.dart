import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:eatwise/core/database/app_database.dart';
import 'package:eatwise/features/planner/domain/planner_task.dart';
import 'package:eatwise/features/planner/data/workout_preset.dart';
import 'package:eatwise/features/dashboard/presentation/screens/dashboard_screen.dart';

class PlannerState {
  final String date;
  final List<PlannerTask> tasks;
  final bool loading;
  const PlannerState({required this.date, this.tasks = const [], this.loading = false});
}

class PlannerNotifier extends StateNotifier<PlannerState> {
  PlannerNotifier() : super(const PlannerState(date: ''));

  Future<void> load(String date) async {
    if (state.date == date && !state.loading) return;
    state = PlannerState(date: date, loading: state.date != date);
    final rows = await PlannerTasksExtension.getTasksForDate(date);
    if (!mounted) return;
    state = PlannerState(date: date, tasks: rows.map((r) => PlannerTask.fromMap(r)).toList());
  }

  Future<void> toggle(int id, bool done) async {
    state = PlannerState(date: state.date, tasks: state.tasks.map((t) => t.id == id ? t.copyWith(isDone: done) : t).toList());
    await PlannerTasksExtension.setTaskDone(id, done);
  }

  Future<void> add({required String taskDate, required String category, required String title, String subtitle = '', bool isHeader = false}) async {
    final t = title.trim(); if (t.isEmpty) return;
    final name = isHeader ? '▸ $t' : t;
    final temp = PlannerTask(id: -DateTime.now().millisecondsSinceEpoch, taskDate: taskDate, category: category, title: name, subtitle: subtitle);
    state = PlannerState(date: state.date, tasks: [...state.tasks, temp]);
    await PlannerTasksExtension.insertTask(taskDate: taskDate, category: category, title: name, subtitle: subtitle);
    await load(taskDate);
  }

  Future<void> remove(int id) async {
    state = PlannerState(date: state.date, tasks: state.tasks.where((t) => t.id != id).toList());
    await PlannerTasksExtension.deleteTask(id);
  }

  Future<void> clearDay(String date) async {
    if (state.date == date) {
      state = PlannerState(date: state.date, tasks: []);
    }
    await PlannerTasksExtension.deleteAllTasksForDate(date);
    await load(state.date);
  }

  Future<void> loadWorkoutPreset(String date) async {
    state = PlannerState(date: date, loading: true);
    await PlannerTasksExtension.deleteAllTasksForDate(date);
    await PlannerTasksExtension.insertTasksBatch(homeWorkoutPreset(date));
    await load(date);
  }
}

final plannerNotifierProvider = StateNotifierProvider.autoDispose<PlannerNotifier, PlannerState>((ref) {
  final n = PlannerNotifier();
  final ds = DateFormat('yyyy-MM-dd').format(ref.watch(selectedDateProvider));
  Future.microtask(() => n.load(ds));
  ref.listen(selectedDateProvider, (_, next) => n.load(DateFormat('yyyy-MM-dd').format(next)));
  return n;
});

final plannerTasksProvider = Provider.autoDispose<List<PlannerTask>>((ref) => ref.watch(plannerNotifierProvider).tasks);