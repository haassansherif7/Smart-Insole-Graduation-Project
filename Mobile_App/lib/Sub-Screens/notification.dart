import 'package:diabetes_project/main.dart';
import 'package:diabetes_project/core/alerts/alert_notifier.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void> showDangerNotification(String message) async {
  if (AlertNotifier.appInForeground) return;

  final notificationId =
      DateTime.now().millisecondsSinceEpoch % 2147483647;

  const AndroidNotificationDetails androidDetails =
      AndroidNotificationDetails(
    'danger_channel',
    'Danger Alerts',
    importance: Importance.max,
    priority: Priority.high,

    // إضافات بدون تغيير منطق الكود
    channelDescription: 'Alerts for dangerous foot temperature',
    playSound: true,
    enableVibration: true,
  );

  const NotificationDetails details =
      NotificationDetails(
    android: androidDetails,
  );

  await notificationsPlugin.show(
    notificationId,
    '⚠️ تحذير',
    message,
    details,
  );
}