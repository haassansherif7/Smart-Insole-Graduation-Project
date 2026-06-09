import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'database_helper.dart';
import 'health_event.dart';

class HealthEventRepository {
  final DatabaseHelper _db;
  static const _table = 'health_events';

  HealthEventRepository({DatabaseHelper? db}) : _db = db ?? DatabaseHelper();

  static String get _currentUserId =>
      Supabase.instance.client.auth.currentUser?.id ?? 'guest';

  Future<void> save(HealthEvent event) async {
    final db = await _db.database;
    final map = event.toMap();
    map['user_id'] = _currentUserId;
    await db.insert(
      _table,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<HealthEvent>> getByType(EventType type) async {
    final db = await _db.database;
    final rows = await db.query(
      _table,
      where: 'event_type = ? AND user_id = ?',
      whereArgs: [type.index, _currentUserId],
      orderBy: 'timestamp DESC',
    );
    return rows.map(HealthEvent.fromMap).toList();
  }

  Future<List<HealthEvent>> getAll({int limit = 50}) async {
    final db = await _db.database;
    final rows = await db.query(
      _table,
      where: 'user_id = ?',
      whereArgs: [_currentUserId],
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return rows.map(HealthEvent.fromMap).toList();
  }

  Future<Map<EventType, HealthEvent?>> getLatestPerType() async {
    final db = await _db.database;
    final result = <EventType, HealthEvent?>{};
    for (final type in EventType.values) {
      final rows = await db.query(
        _table,
        where: 'event_type = ? AND user_id = ?',
        whereArgs: [type.index, _currentUserId],
        orderBy: 'timestamp DESC',
        limit: 1,
      );
      result[type] = rows.isNotEmpty ? HealthEvent.fromMap(rows.first) : null;
    }
    return result;
  }

  Future<List<HealthEvent>> getLast7Days(EventType type) async {
    final db = await _db.database;
    final since =
        DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
    final rows = await db.query(
      _table,
      where: 'event_type = ? AND timestamp >= ? AND user_id = ?',
      whereArgs: [type.index, since, _currentUserId],
      orderBy: 'timestamp ASC',
    );
    return rows.map(HealthEvent.fromMap).toList();
  }

  Future<double> getTrendSlope(EventType type, {int days = 7}) async {
    final events = await getLast7Days(type);
    if (events.length < 2) return 0.0;
    final n = events.length;
    double sx = 0, sy = 0, sxy = 0, sx2 = 0;
    for (int i = 0; i < n; i++) {
      sx += i;
      sy += events[i].riskScore;
      sxy += i * events[i].riskScore;
      sx2 += i * i;
    }
    final denom = n * sx2 - sx * sx;
    return denom == 0 ? 0.0 : (n * sxy - sx * sy) / denom;
  }

  Future<void> deleteOlderThan(Duration duration) async {
    final db = await _db.database;
    final cutoff = DateTime.now().subtract(duration).toIso8601String();
    await db.delete(
      _table,
      where: 'timestamp < ? AND user_id = ?',
      whereArgs: [cutoff, _currentUserId],
    );
  }
}
