import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String kBackgroundTask = 'diabetic_sensor_check';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await Supabase.initialize(
        url: 'https://troryqhoyolczplgegmn.supabase.co',
        anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRyb3J5cWhveW9sY3pwbGdlZ21uIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ4MDc0MjIsImV4cCI6MjA4MDM4MzQyMn0.jt5bt1bJkQTsKYnVWSH8x63qifE5qIX0WBR2N86ICd0',
      );

      final response = await Supabase.instance.client
          .from('readings')
          .select()
          .order('id', ascending: false)
          .limit(1);

      if (response.isEmpty) return true;

      final row = response[0];

      final temps = [
        double.tryParse(row['Temp1'].toString()) ?? 36.5,
        double.tryParse(row['Temp2'].toString()) ?? 36.5,
        double.tryParse(row['BigF_T'].toString()) ?? 36.5,
        double.tryParse(row['Side_T'].toString()) ?? 36.5,
        double.tryParse(row['Center_T'].toString()) ?? 36.5,
      ];

      final pressures = [
        (double.tryParse(row['Pres1'].toString()) ?? 0) / 50,
        (double.tryParse(row['Pres2'].toString()) ?? 0) / 50,
        (double.tryParse(row['BigF_P'].toString()) ?? 0) / 50,
        (double.tryParse(row['Side_P'].toString()) ?? 0) / 50,
        (double.tryParse(row['Center_P'].toString()) ?? 0) / 50,
      ];

      final hasHighTemp = temps.any((t) => t >= 37.5);
      final hasHighPressure = pressures.any((p) => p >= 70);

      if (hasHighTemp || hasHighPressure) {
        final plugin = FlutterLocalNotificationsPlugin();
        const android = AndroidInitializationSettings('@mipmap/ic_launcher');
        await plugin.initialize(
          const InitializationSettings(android: android),
        );

        const String title = '🚨 تحذير صحي / Health Warning';
        String body;

        if (hasHighTemp && hasHighPressure) {
          body = 'ارتفاع في الحرارة والضغط - High temp & pressure detected';
        } else if (hasHighTemp) {
          body = 'ارتفاع في حرارة القدم - High foot temperature';
        } else {
          body = 'ضغط مرتفع على القدم - High foot pressure';
        }

        await plugin.show(
          100,
          title,
          body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'danger_channel',
              'Danger Alerts',
              importance: Importance.max,
              priority: Priority.high,
              enableVibration: true,
              playSound: true,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    } catch (e) {
      // ignore errors in background
    }
    return true;
  });
}

class BackgroundService {
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
  }

  static Future<void> startPeriodicTask() async {
    await Workmanager().registerPeriodicTask(
      kBackgroundTask,
      kBackgroundTask,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  static Future<void> stopTask() async {
    await Workmanager().cancelByUniqueName(kBackgroundTask);
  }
}
