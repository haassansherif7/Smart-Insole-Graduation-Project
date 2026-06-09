import 'dart:async';
import 'package:diabetes_project/core/database/health_event.dart';
import 'package:diabetes_project/core/providers/health_history_provider.dart';
import 'package:flutter/material.dart';
import 'package:diabetes_project/main.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:diabetes_project/core/alerts/alert_notifier.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class DailyMonitoringScreen extends StatefulWidget {
  final Function(String temperature, String pressure)? onSensorUpdate;
  const DailyMonitoringScreen({super.key, this.onSensorUpdate});

  @override
  State<DailyMonitoringScreen> createState() =>
      _DailyMonitoringScreenState();
}

class _DailyMonitoringScreenState
    extends State<DailyMonitoringScreen> {

  List<double> _temperatureReadings = [];
  List<double> _pressureReadings = [];

  String? _aiResult;
  Timer? _timer;

  bool _isFetchingData = false;
  bool _isConnected = true;
  DateTime? _lastUpdated;
  static const Duration _fetchTimeout = Duration(seconds: 6);
  static const Duration _pollInterval = Duration(seconds: 8);

  int? lastReadingId;
  int? _lastNotifiedReadingId;

  double parseValue(dynamic v, double fallback) {
    if (v == null) return fallback;
    return double.tryParse(v.toString()) ?? fallback;
  }

  double _normalizePressure(double rawValue) {
    const double maxRaw = 5000.0;
    final normalized = (rawValue / maxRaw) * 100;
    return normalized.clamp(0.0, 100.0);
  }

  double getTemp(int i) =>
      _temperatureReadings.length > i
          ? _temperatureReadings[i]
          : 0;

  double getPress(int i) =>
      _pressureReadings.length > i
          ? _pressureReadings[i]
          : 0;

  double get _overallFootTemp {
    if (_temperatureReadings.isEmpty) return 0;
    final sum = _temperatureReadings.reduce((v, e) => v + e);
    return sum / _temperatureReadings.length;
  }

  bool get _hasHighTemp =>
      _temperatureReadings.any((t) => t >= 37.5);

  bool get _hasHighPressure =>
      _pressureReadings.any((p) => p >= 70);

  String _formatLastUpdated(bool isArabic) {
    if (_lastUpdated == null) {
      return isArabic ? 'لا توجد بيانات' : 'No data';
    }
    final diff = DateTime.now().difference(_lastUpdated!);
    if (diff.inSeconds < 10) {
      return isArabic ? 'الآن' : 'Just now';
    }
    if (diff.inMinutes < 1) {
      return isArabic ? 'منذ ${diff.inSeconds} ثانية' : '${diff.inSeconds} sec ago';
    }
    return isArabic ? 'منذ ${diff.inMinutes} دقيقة' : '${diff.inMinutes} min ago';
  }

  @override
  void initState() {
    super.initState();

    notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _fetchSensorData();

    _timer = Timer.periodic(
      _pollInterval,
      (_) {
        if (!_isFetchingData) _fetchSensorData();
      },
    );
  }

  double _sensorRiskScore() {
    if (_hasHighTemp && _hasHighPressure) return 0.85;
    if (_hasHighTemp) return 0.55;
    if (_hasHighPressure) return 0.45;
    return 0.1;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchSensorData() async {
    if (_isFetchingData) return;
    _isFetchingData = true;

    final supabase = Supabase.instance.client;

    try {
      final response = await supabase
          .from('readings')
          .select()
          .order('id', ascending: false)
          .limit(1)
          .timeout(_fetchTimeout);

      if (response.isEmpty) return;

      final row = response[0];

      if (!mounted) return;
      final settings =
          Provider.of<AppSettings>(context, listen: false);

      final isArabic = settings.locale.languageCode == 'ar';

      final currentId = row['id'];

      String message = '';

      setState(() {
        _lastUpdated = DateTime.now();
        _isConnected = true;
        _temperatureReadings = [
          parseValue(row['Temp1'], 36.5),
          parseValue(row['Temp2'], 36.5),
          parseValue(row['BigF_T'], 36.5),
          parseValue(row['Side_T'], 36.5),
          parseValue(row['Center_T'], 36.5),
        ];

        _pressureReadings = [
          _normalizePressure(parseValue(row['Pres1'], 0)),
          _normalizePressure(parseValue(row['Pres2'], 0)),
          _normalizePressure(parseValue(row['BigF_P'], 0)),
          _normalizePressure(parseValue(row['Side_P'], 0)),
          _normalizePressure(parseValue(row['Center_P'], 0)),
        ];

        if (_hasHighTemp && _hasHighPressure) {
          message = isArabic
              ? "⚠️ ارتفاع في الحرارة والضغط، يُفضل مراجعة الطبيب"
              : "High temperature and pressure detected";
        } else if (_hasHighTemp) {
          message = isArabic
              ? "⚠️ يوجد ارتفاع في حرارة القدم"
              : "High foot temperature detected";
        } else if (_hasHighPressure) {
          message = isArabic
              ? "⚠️ يوجد ضغط مرتفع على القدم"
              : "High foot pressure detected";
        } else {
          message = isArabic
              ? "القراءات طبيعية حالياً"
              : "Readings are normal";
        }

        _aiResult = message;
      });

      widget.onSensorUpdate?.call(
        _overallFootTemp.toStringAsFixed(1),
        _hasHighPressure ? 'high' : 'normal',
      );

      final bool isDangerInApp = _hasHighTemp || _hasHighPressure;

      if (isDangerInApp && _lastNotifiedReadingId != currentId) {
        _lastNotifiedReadingId = currentId;
        {

          final plugin = FlutterLocalNotificationsPlugin();
          const android = AndroidInitializationSettings('@mipmap/ic_launcher');
          await plugin.initialize(
            const InitializationSettings(android: android),
          );

          String title;
          String body;

          if (_hasHighTemp && _hasHighPressure) {
            title = isArabic ? '🚨 خطر عالي' : '🚨 High Risk';
            body = isArabic
                ? 'ارتفاع في الحرارة والضغط - راجع طبيبك'
                : 'High temperature & pressure - See your doctor';
          } else if (_hasHighTemp) {
            title = isArabic ? '⚠️ تحذير حرارة' : '⚠️ Temperature Warning';
            body = isArabic
                ? 'ارتفاع في حرارة القدم'
                : 'High foot temperature detected';
          } else {
            title = isArabic ? '⚠️ تحذير ضغط' : '⚠️ Pressure Warning';
            body = isArabic
                ? 'ضغط مرتفع على القدم'
                : 'High foot pressure detected';
          }

          await plugin.show(
            1,
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
      }

      bool isNewReading = lastReadingId != currentId;
      bool isDanger = _hasHighTemp || _hasHighPressure;

      if (isDanger && !AlertNotifier.appInForeground && _lastNotifiedReadingId != currentId) {
        debugPrint('=== DANGER NOTIF: Sending background notification ===');
        final plugin = FlutterLocalNotificationsPlugin();
        const android = AndroidInitializationSettings('@mipmap/ic_launcher');
        await plugin.initialize(const InitializationSettings(android: android));

        final title = isArabic ? '🚨 تحذير صحي' : '🚨 Health Warning';
        final body = _aiResult ?? (isArabic ? 'يوجد خطر على القدم' : 'Foot danger detected');

        await plugin.show(
          1,
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

      if (isNewReading && mounted) {
        final score = _sensorRiskScore();
        final level = score >= 0.8
            ? RiskLevel.critical
            : score >= 0.55
                ? RiskLevel.warning
                : score >= 0.25
                    ? RiskLevel.info
                    : RiskLevel.none;
        // ignore: use_build_context_synchronously
        context.read<HealthHistoryProvider>().saveAndRefresh(
          HealthEvent(
            eventType: EventType.sensorScan,
            riskScore: score,
            riskLevel: level,
          ),
        );
      }

      lastReadingId = currentId;

    } on TimeoutException catch (e) {
      debugPrint("Sensor fetch timed out: $e");
      if (mounted) setState(() => _isConnected = false);
    } catch (e) {
      debugPrint("ERROR: $e");
    } finally {
      _isFetchingData = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AppSettings>(context);
    final isArabic = settings.locale.languageCode == 'ar';
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildStatusCard(isArabic),
              const SizedBox(height: 16),

              if (_aiResult != null)
                _buildAiCard(isArabic),

              const SizedBox(height: 16),

              Text(
                isArabic ? 'خريطة القدم' : 'Foot Map',
                style: theme.textTheme.titleLarge,
              ),

              const SizedBox(height: 10),

              SizedBox(
                height: 350,
                child: _buildFootMap(),
              ),

              const SizedBox(height: 12),
              _buildLegend(isArabic),

              const SizedBox(height: 16),

              _buildAverageCard(isArabic),

              const SizedBox(height: 16),

              _buildAlerts(isArabic),

              const SizedBox(height: 16),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(bool isArabic) {
    String text;
    Color color;
    IconData icon;

    if (_hasHighTemp && _hasHighPressure) {
      text = isArabic ? 'خطر عالي' : 'High Risk';
      color = Colors.red;
      icon = Icons.warning;
    } else if (_hasHighTemp) {
      text = isArabic ? 'تحذير حرارة' : 'Temperature Warning';
      color = Colors.orange;
      icon = Icons.thermostat;
    } else if (_hasHighPressure) {
      text = isArabic ? 'تحذير ضغط' : 'Pressure Warning';
      color = Colors.orange;
      icon = Icons.compress;
    } else {
      text = isArabic ? 'ممتاز' : 'Good';
      color = Colors.green;
      icon = Icons.check_circle;
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Icon(icon, color: color, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic ? 'الحالة الحالية' : 'Current Status',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        text,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 18, color: Theme.of(context).textTheme.bodySmall?.color),
                const SizedBox(width: 6),
                Text(
                  isArabic
                      ? 'آخر تحديث: ${_formatLastUpdated(isArabic)}'
                      : 'Last Updated: ${_formatLastUpdated(isArabic)}',
                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 13),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _isConnected
                        ? Colors.green.withValues(alpha: 0.15)
                        : Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.circle, size: 10,
                          color: _isConnected ? Colors.green : Colors.red),
                      const SizedBox(width: 6),
                      Text(
                        _isConnected
                            ? (isArabic ? 'متصل' : 'Connected')
                            : (isArabic ? 'غير متصل' : 'Disconnected'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _isConnected ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiCard(bool isArabic) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.info),
        title: Text(isArabic ? 'نتيجة الحالة' : 'Status Result'),
        subtitle: Text(_aiResult ?? ''),
      ),
    );
  }

  Widget _buildFootMap() {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: FootPainter(
              baseColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF2A2A3E)
                  : Colors.grey.shade200,
              shadowColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black
                  : Colors.grey,
            ),
          ),
        ),
        _dot(getTemp(0), const Alignment(0, -0.7), true),
        _dot(getTemp(1), const Alignment(0, 0.9), true),
        _dot(getTemp(2), const Alignment(-0.3, -0.9), true),
        _dot(getTemp(3), const Alignment(0.5, 0.1), true),
        _dot(getTemp(4), const Alignment(0, 0), true),
        _dot(getPress(0), const Alignment(0.2, -0.6), false),
        _dot(getPress(1), const Alignment(0.2, 0.85), false),
        _dot(getPress(2), const Alignment(-0.4, -0.85), false),
        _dot(getPress(3), const Alignment(0.6, 0.2), false),
        _dot(getPress(4), const Alignment(0.2, 0.1), false),
      ],
    );
  }

  Widget _dot(double v, Alignment a, bool isTemp) {
    Color c;

    if (isTemp) {
      if (v >= 37.5) { c = Colors.red; }
      else if (v >= 36.5) { c = Colors.orange; }
      else { c = Colors.blue; }
    } else {
      if (v >= 70) { c = Colors.redAccent; }
      else if (v >= 50) { c = Colors.orangeAccent; }
      else { c = Colors.blueAccent; }
    }

    return Align(
      alignment: a,
      child: Container(
        width: isTemp ? 26 : 18,
        height: isTemp ? 26 : 18,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c,
          shape: BoxShape.circle,
        ),
        child: Text(
          isTemp
              ? v.toStringAsFixed(1)
              : v.toStringAsFixed(0),
          style: const TextStyle(
            fontSize: 8,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildAverageCard(bool isArabic) {
    final avgPressure = _pressureReadings.isEmpty
        ? 0.0
        : _pressureReadings.reduce((a, b) => a + b) / _pressureReadings.length;

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.thermostat, color: Colors.orange),
            title: Text(isArabic ? 'متوسط الحرارة' : 'Average Temperature'),
            subtitle: Text('${_overallFootTemp.toStringAsFixed(1)} °C'),
            trailing: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchSensorData,
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              Icons.compress,
              color: avgPressure >= 70
                  ? Colors.red
                  : avgPressure >= 50
                      ? Colors.orange
                      : Colors.blue,
            ),
            title: Text(isArabic ? 'متوسط الضغط' : 'Average Pressure'),
            subtitle: Text(
              '${avgPressure.toStringAsFixed(1)}%  '
              '${avgPressure >= 70
                  ? (isArabic ? '⚠️ مرتفع' : '⚠️ High')
                  : avgPressure >= 50
                      ? (isArabic ? 'متوسط' : 'Moderate')
                      : (isArabic ? 'طبيعي' : 'Normal')}',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlerts(bool isArabic) {
    List<String> alerts = [];

    if (_hasHighTemp) {
      alerts.add(isArabic ? 'ارتفاع في درجة الحرارة' : 'High temperature');
    }

    if (_hasHighPressure) {
      alerts.add(isArabic ? 'ضغط عالي على القدم' : 'High pressure detected');
    }

    if (alerts.isEmpty) return const SizedBox();

    return Card(
      child: Column(
        children: alerts
            .map((a) => ListTile(
                  leading: const Icon(Icons.warning, color: Colors.red),
                  title: Text(a),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildLegend(bool isArabic) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isArabic ? 'دليل الألوان' : 'Color Legend',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 10,
              children: [
                _legendItem(Colors.red, isArabic ? 'خطر' : 'High Risk'),
                _legendItem(Colors.orange, isArabic ? 'متوسط' : 'Medium'),
                _legendItem(Colors.blue, isArabic ? 'طبيعي' : 'Normal'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(text),
      ],
    );
  }
}

class FootPainter extends CustomPainter {
  final Color baseColor;
  final Color shadowColor;

  FootPainter({required this.baseColor, required this.shadowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = baseColor;

    final path = Path();
    path.addOval(Rect.fromLTWH(
        size.width * 0.2, 0, size.width * 0.6, size.height));

    canvas.drawShadow(path, shadowColor, 8, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}