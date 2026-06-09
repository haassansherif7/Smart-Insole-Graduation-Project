import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'alert_engine.dart';

class AlertNotifier {
  // App lifecycle state - set from main.dart
  static bool appInForeground = true;

  static const _criticalCooldownMs = 60 * 1000;       // 1 minute
  static const _warningCooldownMs  = 5 * 60 * 1000;   // 5 minutes

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: android));
    _initialized = true;
  }

  Future<void> notify(AlertResult alert, {bool isArabic = true}) async {
    // Only notify for warning or critical
    if (alert.level == AlertLevel.none || alert.level == AlertLevel.info) return;

    final prefs = await SharedPreferences.getInstance();
    final lastTime  = prefs.getInt('last_notif_time') ?? 0;
    final lastScore = double.tryParse(prefs.getString('last_notif_score') ?? '0') ?? 0.0;
    final lastLevelStr = prefs.getString('last_notif_level') ?? 'none';
    final now = DateTime.now().millisecondsSinceEpoch;

    final lastLevel = AlertLevel.values.firstWhere(
      (e) => e.name == lastLevelStr,
      orElse: () => AlertLevel.none,
    );

    // Check if level escalated (e.g. warning → critical)
    final levelEscalated = _levelIndex(alert.level) > _levelIndex(lastLevel);

    if (!levelEscalated) {
      // Apply cooldown based on level
      final cooldown = alert.level == AlertLevel.critical
          ? _criticalCooldownMs
          : _warningCooldownMs;

      if (now - lastTime < cooldown) return;

      // For warning: score must increase by 10%
      // For critical: always notify (no score delta needed)
      if (alert.level == AlertLevel.warning) {
        if (alert.score - lastScore < 0.10) return;
      }
    }

    // Save notification state
    await prefs.setInt('last_notif_time', now);
    await prefs.setString('last_notif_score', alert.score.toString());
    await prefs.setString('last_notif_level', alert.level.name);

    debugPrint('=== NOTIF: foreground=${AlertNotifier.appInForeground} ===');

    // If app is in foreground → skip system notification
    // Dashboard alert_banner handles in-app display
    if (appInForeground) return;

    // App is in background → send sound notification
    await _ensureInit();

    final isCritical = alert.level == AlertLevel.critical;

    final title = isCritical
        ? (isArabic ? '🚨 تحذير حرج - يحتاج تدخل فوري' : '🚨 Critical Alert - Immediate Action')
        : (isArabic ? '⚠️ تحذير صحي' : '⚠️ Health Warning');

    final body = alert.arabicMessage;

    await _plugin.show(
      isCritical ? 1 : 2,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'danger_channel',
          'Danger Alerts',
          importance: isCritical ? Importance.max : Importance.high,
          priority: isCritical ? Priority.max : Priority.high,
          enableVibration: true,
          playSound: true,
          icon: '@mipmap/ic_launcher',
          // Critical notifications are ongoing (can't be dismissed easily)
          ongoing: isCritical,
          autoCancel: !isCritical,
        ),
      ),
    );
  }

  // Cancel ongoing critical notification when risk goes down
  Future<void> cancelIfSafe(AlertLevel currentLevel) async {
    if (currentLevel == AlertLevel.none || currentLevel == AlertLevel.info) {
      await _ensureInit();
      await _plugin.cancel(1); // Cancel critical
      await _plugin.cancel(2); // Cancel warning
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_notif_level', 'none');
      await prefs.setString('last_notif_score', '0');
    }
  }

  int _levelIndex(AlertLevel l) {
    switch (l) {
      case AlertLevel.none:     return 0;
      case AlertLevel.info:     return 1;
      case AlertLevel.warning:  return 2;
      case AlertLevel.critical: return 3;
    }
  }
}
