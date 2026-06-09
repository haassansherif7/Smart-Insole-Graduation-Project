import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:diabetes_project/core/database/database_helper.dart';
import 'package:diabetes_project/features/nutrition/nutrition_service.dart';

class NutritionProvider extends ChangeNotifier {
  final DatabaseHelper _db;
  static const _table = 'nutrition_logs';

  List<MealEntry> _todayMeals = [];
  DailySummary _summary = const DailySummary(
    totalCalories: 0,
    totalCarbs: 0,
    totalProtein: 0,
    totalFat: 0,
    totalFiber: 0,
    avgGlucoseImpact: 0,
    mealCount: 0,
    meals: [],
  );
  bool _loading = false;
  String? _error;
  UserFoodPreferences _preferences = const UserFoodPreferences();
  bool _prefsLoaded = false;

  NutritionProvider({DatabaseHelper? db}) : _db = db ?? DatabaseHelper();

  List<MealEntry> get todayMeals => _todayMeals;
  DailySummary get summary => _summary;
  bool get loading => _loading;
  String? get error => _error;
  UserFoodPreferences get preferences => _preferences;

  /// Load preferences from SharedPreferences (no-op if already loaded).
  Future<void> loadPreferences() async {
    if (_prefsLoaded) return;
    _preferences = await NutritionService.loadPreferences();
    _prefsLoaded = true;
    notifyListeners();
  }

  /// Persist updated preferences and notify listeners.
  Future<void> savePreferences(UserFoodPreferences prefs) async {
    _preferences = prefs;
    await NutritionService.savePreferences(prefs);
    notifyListeners();
  }

  Future<void> loadToday() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day).toIso8601String();
      final end =
          DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();
      final db = await _db.database;
      final rows = await db.query(
        _table,
        where: 'timestamp >= ? AND timestamp <= ?',
        whereArgs: [start, end],
        orderBy: 'timestamp DESC',
      );
      _todayMeals = rows.map(MealEntry.fromMap).toList();
      _summary = NutritionService.computeSummary(_todayMeals);
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> logMeal(MealEntry meal) async {
    final db = await _db.database;
    await db.insert(
      _table,
      meal.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await loadToday();
  }

  Future<void> deleteMeal(String id) async {
    final db = await _db.database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
    await loadToday();
  }

  Future<List<MealEntry>> getMealsForDate(DateTime date) async {
    final db = await _db.database;
    final start = DateTime(date.year, date.month, date.day).toIso8601String();
    final end =
        DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();
    final rows = await db.query(
      _table,
      where: 'timestamp >= ? AND timestamp <= ?',
      whereArgs: [start, end],
      orderBy: 'timestamp ASC',
    );
    return rows.map(MealEntry.fromMap).toList();
  }
}
