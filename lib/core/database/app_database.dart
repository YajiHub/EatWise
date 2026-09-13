import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:eatwise/features/food_ai/domain/food_item.dart';

class AppDatabase {
  static Database? _db;

  static Future<Database> get instance async {
    _db ??= await _init();
    return _db!;
  }

  static Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'eatwise.db'),
      version: 7,
      onCreate: (db, v) async {
        await _createTables(db);
        debugPrint('[DB] Created fresh DB v$v');
      },
      onUpgrade: (db, oldV, newV) async {
        if (kDebugMode) debugPrint('[DB] Upgrading v$oldV → v$newV');
        if (oldV < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS user_settings (
              key TEXT PRIMARY KEY,
              value TEXT NOT NULL
            )
          ''');
        }
        if (oldV < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS weight_history (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              date TEXT NOT NULL,
              weight_kg REAL NOT NULL,
              height_cm REAL,
              created_at TEXT NOT NULL
            )
          ''');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_weight_date ON weight_history(date DESC)');
        }
        if (oldV < 4) {
          try {
            await db.execute("ALTER TABLE food_logs ADD COLUMN image_path TEXT DEFAULT ''");
            debugPrint('[DB] Migrated v4: added image_path column');
          } catch (e) {
            // Column may already exist if onCreate already added it
            debugPrint('[DB] v4 image_path migration (safe to ignore if column exists): $e');
          }
        }
        if (oldV < 5) {
          // v5: ensure all required columns exist for older installs
          for (final col in [
            "ALTER TABLE food_logs ADD COLUMN meal_type TEXT DEFAULT 'unknown'",
            "ALTER TABLE food_logs ADD COLUMN source TEXT DEFAULT 'chat'",
            "ALTER TABLE food_logs ADD COLUMN total_calories REAL DEFAULT 0",
            "ALTER TABLE food_logs ADD COLUMN total_protein_g REAL DEFAULT 0",
            "ALTER TABLE food_logs ADD COLUMN total_carbs_g REAL DEFAULT 0",
            "ALTER TABLE food_logs ADD COLUMN total_fats_g REAL DEFAULT 0",
            "ALTER TABLE food_logs ADD COLUMN summary TEXT DEFAULT ''",
            "ALTER TABLE food_logs ADD COLUMN image_path TEXT DEFAULT ''",
          ]) {
            try {
              await db.execute(col);
            } catch (_) {} // Ignore duplicate column errors
          }
          if (kDebugMode) debugPrint('[DB] Migrated v5: verified all food_logs columns');
        }
        if (oldV < 6) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS planner_tasks (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              task_date TEXT NOT NULL,
              category TEXT NOT NULL,
              title TEXT NOT NULL,
              subtitle TEXT DEFAULT '',
              sort_order INTEGER DEFAULT 0,
              is_done INTEGER DEFAULT 0,
              created_at TEXT DEFAULT (datetime('now'))
            )
          ''');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_planner_date ON planner_tasks(task_date)');
          debugPrint('[DB] Migrated v6: added planner_tasks table');
        }
        if (oldV < 7) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS chat_history (
              id TEXT PRIMARY KEY,
              session_id TEXT NOT NULL DEFAULT 'default',
              role TEXT NOT NULL,
              text TEXT NOT NULL,
              image_paths TEXT DEFAULT '[]',
              meal_result_json TEXT,
              created_at INTEGER NOT NULL
            )
          ''');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_chat_session ON chat_history(session_id, created_at)');
          if (kDebugMode) debugPrint('[DB] Migrated v7: ensured chat_history table');
        }
        if (kDebugMode) debugPrint('[DB] Upgrade complete: v$oldV → v$newV');
      },
    );
  }

  static Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE food_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        log_date TEXT NOT NULL,
        meal_type TEXT DEFAULT 'unknown',
        source TEXT DEFAULT 'chat',
        raw_json TEXT NOT NULL,
        total_calories REAL DEFAULT 0,
        total_protein_g REAL DEFAULT 0,
        total_carbs_g REAL DEFAULT 0,
        total_fats_g REAL DEFAULT 0,
        summary TEXT DEFAULT '',
        image_path TEXT DEFAULT '',
        created_at TEXT DEFAULT (datetime('now'))
      )
    ''');
    await db.execute('''
      CREATE TABLE daily_steps (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        step_date TEXT NOT NULL UNIQUE,
        total_steps INTEGER DEFAULT 0,
        distance_km REAL DEFAULT 0,
        calories_burned REAL DEFAULT 0,
        created_at TEXT DEFAULT (datetime('now'))
      )
    ''');
    await db.execute('''
      CREATE TABLE user_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE weight_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        weight_kg REAL NOT NULL,
        height_cm REAL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_weight_date ON weight_history(date DESC)');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS chat_history (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL DEFAULT 'default',
        role TEXT NOT NULL,
        text TEXT NOT NULL,
        image_paths TEXT DEFAULT '[]',
        meal_result_json TEXT,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_chat_session ON chat_history(session_id, created_at)');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS planner_tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_date TEXT NOT NULL,
        category TEXT NOT NULL,
        title TEXT NOT NULL,
        subtitle TEXT DEFAULT '',
        sort_order INTEGER DEFAULT 0,
        is_done INTEGER DEFAULT 0,
        created_at TEXT DEFAULT (datetime('now'))
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_planner_date ON planner_tasks(task_date)');
  }

  // ── Settings ──

  static Future<void> setSetting(String key, String value) async {
    final db = await instance;
    await db.insert('user_settings', {'key': key, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<String?> getSetting(String key) async {
    final db = await instance;
    final rows = await db.query('user_settings', where: 'key = ?', whereArgs: [key]);
    return rows.isNotEmpty ? rows.first['value'] as String? : null;
  }

  static Future<double> getNumericSetting(String key, double fallback) async {
    final raw = await getSetting(key);
    if (raw == null) return fallback;
    return double.tryParse(raw) ?? fallback;
  }

  static Future<int> getIntSetting(String key, int fallback) async {
    final raw = await getSetting(key);
    if (raw == null) return fallback;
    return int.tryParse(raw) ?? fallback;
  }

  // ── Food Logs ──

  static Future<int> insertFoodLog({
    required String logDate,
    required String mealType,
    required String source,
    required MealAnalysis meal,
    String? imagePath,
  }) async {
    final db = await instance;
    return db.insert('food_logs', {
      'log_date': logDate,
      'meal_type': mealType,
      'source': source,
      'raw_json': jsonEncode(meal.toJson()),
      'total_calories': meal.totalCalories,
      'total_protein_g': meal.totalProtein,
      'total_carbs_g': meal.totalCarbs,
      'total_fats_g': meal.totalFats,
      'summary': meal.summary,
      'image_path': imagePath ?? '',
    });
  }

  static Future<List<Map<String, dynamic>>> getLogsForDate(String date) async {
    final db = await instance;
    return db.query('food_logs', where: 'log_date = ?', whereArgs: [date], orderBy: 'id DESC');
  }

  static Future<Map<String, double>> getDailyTotals(String date) async {
    final db = await instance;
    final r = await db.rawQuery(
      'SELECT SUM(total_calories) as cal, SUM(total_protein_g) as p, SUM(total_carbs_g) as c, SUM(total_fats_g) as f FROM food_logs WHERE log_date = ?',
      [date],
    );
    final row = r.first;
    return {
      'calories': (row['cal'] as num?)?.toDouble() ?? 0,
      'protein': (row['p'] as num?)?.toDouble() ?? 0,
      'carbs': (row['c'] as num?)?.toDouble() ?? 0,
      'fats': (row['f'] as num?)?.toDouble() ?? 0,
    };
  }

  static Future<int> deleteLog(int id) async {
    final db = await instance;
    final rows = await db.query('food_logs', where: 'id = ?', whereArgs: [id], columns: ['image_path']);
    if (rows.isNotEmpty) {
      final imagePath = rows.first['image_path'] as String?;
      if (imagePath != null && imagePath.isNotEmpty) {
        try { await File(imagePath).delete(); } catch (_) {}
      }
    }
    return db.delete('food_logs', where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> deleteLogsForDate(String date) async {
    final db = await instance;
    return db.delete('food_logs', where: 'log_date = ?', whereArgs: [date]);
  }

  static Future<int> updateFoodLog(int id, {
    required String mealType,
    required String rawJson,
    required double totalCalories,
    required double totalProtein,
    required double totalCarbs,
    required double totalFats,
    required String summary,
    String? imagePath,
  }) async {
    final db = await instance;
    return db.update('food_logs', {
      'meal_type': mealType,
      'raw_json': rawJson,
      'total_calories': totalCalories,
      'total_protein_g': totalProtein,
      'total_carbs_g': totalCarbs,
      'total_fats_g': totalFats,
      'summary': summary,
      if (imagePath != null) 'image_path': imagePath,
    }, where: 'id = ?', whereArgs: [id]);
  }

  // ── Steps ──

  static Future<void> upsertDailySteps({
    required String date,
    required int steps,
    required double distanceKm,
    required double calories,
  }) async {
    final db = await instance;
    await db.insert('daily_steps', {
      'step_date': date,
      'total_steps': steps,
      'distance_km': distanceKm,
      'calories_burned': calories,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ── Weight ──

  static Future<int> insertWeight({
    required String date,
    required double weightKg,
    double? heightCm,
  }) async {
    final db = await instance;
    return db.insert('weight_history', {
      'date': date,
      'weight_kg': weightKg,
      'height_cm': heightCm,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getWeightHistory({int? limit}) async {
    final db = await instance;
    return db.query('weight_history', orderBy: 'date DESC', limit: limit);
  }

  static Future<Map<String, dynamic>?> getLatestWeight() async {
    final db = await instance;
    final rows = await db.query('weight_history', orderBy: 'date DESC', limit: 1);
    return rows.isNotEmpty ? rows.first : null;
  }

  static Future<Map<String, dynamic>?> getWeightForDate(String date) async {
    final db = await instance;
    final rows = await db.query('weight_history', where: 'date = ?', whereArgs: [date], limit: 1);
    return rows.isNotEmpty ? rows.first : null;
  }

  static Future<void> updateWeight(int id, double weightKg) async {
    final db = await instance;
    await db.update('weight_history', {'weight_kg': weightKg}, where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> deleteWeight(int id) async {
    final db = await instance;
    await db.delete('weight_history', where: 'id = ?', whereArgs: [id]);
  }

  static Future<bool> hasWeightOnDate(String date) async {
    final db = await instance;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM weight_history WHERE date = ?', [date]));
    return (count ?? 0) > 0;
  }

  // ── Aggregation Queries ──

  static Future<List<Map<String, dynamic>>> getWeekSummaries(List<String> dates) async {
    if (dates.isEmpty) return [];
    final db = await instance;
    final placeholders = dates.map((_) => '?').join(',');
    return db.rawQuery('''
      SELECT log_date, SUM(total_calories) as cal, SUM(total_protein_g) as p,
             SUM(total_carbs_g) as c, SUM(total_fats_g) as f, COUNT(*) as meal_count
      FROM food_logs WHERE log_date IN ($placeholders)
      GROUP BY log_date ORDER BY log_date
    ''', dates);
  }

  static Future<Set<int>> getMonthLoggedDays(int year, int month) async {
    final db = await instance;
    final prefix = '$year-${month.toString().padLeft(2, '0')}';
    final rows = await db.rawQuery('''
      SELECT DISTINCT CAST(substr(log_date, 9, 2) AS INTEGER) as day_num
      FROM food_logs WHERE log_date LIKE ?
    ''', ['$prefix%']);
    return rows.map((r) => r['day_num'] as int).toSet();
  }

  static Future<Map<int, double>> getMonthDayCalories(int year, int month) async {
    final db = await instance;
    final prefix = '$year-${month.toString().padLeft(2, '0')}';
    final rows = await db.rawQuery('''
      SELECT CAST(substr(log_date, 9, 2) AS INTEGER) as day_num,
             SUM(total_calories) as total_cal
      FROM food_logs WHERE log_date LIKE ?
      GROUP BY day_num
    ''', ['$prefix%']);
    return {for (final r in rows) r['day_num'] as int: (r['total_cal'] as num?)?.toDouble() ?? 0};
  }

  static Future<Map<String, double>> getDateRangeTotals(String startDate, String endDate) async {
    final db = await instance;
    final r = await db.rawQuery('''
      SELECT SUM(total_calories) as cal, SUM(total_protein_g) as p,
             SUM(total_carbs_g) as c, SUM(total_fats_g) as f,
             COUNT(DISTINCT log_date) as logged_days
      FROM food_logs WHERE log_date >= ? AND log_date <= ?
    ''', [startDate, endDate]);
    final row = r.first;
    return {
      'calories': (row['cal'] as num?)?.toDouble() ?? 0,
      'protein': (row['p'] as num?)?.toDouble() ?? 0,
      'carbs': (row['c'] as num?)?.toDouble() ?? 0,
      'fats': (row['f'] as num?)?.toDouble() ?? 0,
      'logged_days': ((row['logged_days'] as num?)?.toDouble() ?? 0),
    };
  }

  static Future<Map<String, double>> getMonthlyTotals(int year, int month) async {
    final startDate = '$year-${month.toString().padLeft(2, '0')}-01';
    final lastDay = DateTime(year, month + 1, 0).day;
    final endDate = '$year-${month.toString().padLeft(2, '0')}-$lastDay';
    return getDateRangeTotals(startDate, endDate);
  }

  static Future<int> getStreak([String? anchorDate]) async {
    final db = await instance;
    final now = DateTime.now();

    DateTime startFrom;
    if (anchorDate == null || anchorDate.trim().isEmpty) {
      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final todayCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM food_logs WHERE log_date = ?', [todayStr]),
      ) ?? 0;

      if (todayCount > 0) {
        startFrom = now;
      } else {
        final yesterday = now.subtract(const Duration(days: 1));
        final yesterdayStr = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
        final yesterdayCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM food_logs WHERE log_date = ?', [yesterdayStr]),
        ) ?? 0;
        if (yesterdayCount > 0) {
          startFrom = yesterday;
        } else {
          return 0; // Inactive for 2+ days or weeks
        }
      }
    } else {
      startFrom = DateTime.tryParse(anchorDate) ?? now;
    }

    int streak = 0;
    var current = startFrom;
    while (true) {
      final dateStr = '${current.year}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')}';
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM food_logs WHERE log_date = ?', [dateStr]),
      );
      if ((count ?? 0) == 0) break;
      streak++;
      current = current.subtract(const Duration(days: 1));
    }
    return streak;
  }
}

// ── Chat History ──

extension ChatHistoryExtension on AppDatabase {
  static Future<void> insertChatMessage({
    required String id,
    required String role,
    required String text,
    String sessionId = 'default',
    String? imagePaths,
    String? mealResultJson,
    int? createdAt,
  }) async {
    final db = await AppDatabase.instance;
    await db.insert('chat_history', {
      'id': id,
      'session_id': sessionId,
      'role': role,
      'text': text,
      'image_paths': imagePaths ?? '[]',
      'meal_result_json': mealResultJson,
      'created_at': createdAt ?? DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getChatSession({
    String sessionId = 'default',
    int limit = 200,
  }) async {
    final db = await AppDatabase.instance;
    return db.query('chat_history',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'created_at ASC',
      limit: limit,
    );
  }

  static Future<void> deleteChatMessagesAfter(String id, {String sessionId = 'default'}) async {
    final db = await AppDatabase.instance;
    final rows = await db.query('chat_history',
      where: 'session_id = ? AND id = ?', whereArgs: [sessionId, id], columns: ['created_at']);
    if (rows.isEmpty) return;
    final timestamp = rows.first['created_at'] as int;
    await db.delete('chat_history',
      where: 'session_id = ? AND created_at >= ?', whereArgs: [sessionId, timestamp]);
  }

  static Future<void> deleteChatMessage(String id) async {
    final db = await AppDatabase.instance;
    await db.delete('chat_history', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> clearChatSession({String sessionId = 'default'}) async {
    final db = await AppDatabase.instance;
    await db.delete('chat_history', where: 'session_id = ?', whereArgs: [sessionId]);
  }
}


// ── Planner / To-Do ──

extension PlannerTasksExtension on AppDatabase {

  static Future<List<Map<String, dynamic>>> getTasksForDate(String date) async {
    final db = await AppDatabase.instance;
    return db.query('planner_tasks',
        where: 'task_date = ?', whereArgs: [date], orderBy: 'category, sort_order');
  }

  static Future<int> insertTask({
    required String taskDate,
    required String category,
    required String title,
    String subtitle = '',
    int sortOrder = 0,
  }) async {
    final db = await AppDatabase.instance;
    return db.insert('planner_tasks', {
      'task_date': taskDate,
      'category': category,
      'title': title,
      'subtitle': subtitle,
      'sort_order': sortOrder,
      'is_done': 0,
    });
  }

  static Future<void> setTaskDone(int id, bool done) async {
    final db = await AppDatabase.instance;
    await db.update('planner_tasks', {'is_done': done ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> deleteTask(int id) async {
    final db = await AppDatabase.instance;
    await db.delete('planner_tasks', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> deleteAllTasksForDate(String date) async {
    final db = await AppDatabase.instance;
    await db.delete('planner_tasks', where: 'task_date = ?', whereArgs: [date]);
  }

  /// Batch insert tasks — used for loading the workout preset
  static Future<void> insertTasksBatch(List<Map<String, dynamic>> tasks) async {
    final db = await AppDatabase.instance;
    final batch = db.batch();
    for (final t in tasks) {
      batch.insert('planner_tasks', t, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  /// Check if a date has planner tasks
  static Future<bool> hasTasksForDate(String date) async {
    final db = await AppDatabase.instance;
    final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM planner_tasks WHERE task_date = ?', [date]));
    return (count ?? 0) > 0;
  }
}
