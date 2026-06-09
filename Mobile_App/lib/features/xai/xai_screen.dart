import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:diabetes_project/core/database/health_event.dart';
import 'package:diabetes_project/core/providers/health_history_provider.dart';
import 'package:diabetes_project/features/xai/xai_service.dart';
import 'package:diabetes_project/main.dart';
import 'package:diabetes_project/core/widgets/chatbot_fab.dart';

class XaiScreen extends StatefulWidget {
  const XaiScreen({super.key});

  @override
  State<XaiScreen> createState() => _XaiScreenState();
}

class _XaiScreenState extends State<XaiScreen> {
  final _service = XaiService();
  bool _loading = false;
  Map<String, dynamic>? _result;
  String? _error;

  String _getEventTypeName(EventType type, bool isArabic) {
    if (!isArabic) {
      switch (type) {
        case EventType.sensorScan:
          return 'Sensor Scan';
        case EventType.imageAnalysis:
          return 'Image Analysis';
        case EventType.strokePrediction:
          return 'Stroke Risk';
        case EventType.generalHealth:
          return 'General Health';
      }
    }
    switch (type) {
      case EventType.sensorScan:
        return 'فحص الاستشعار';
      case EventType.imageAnalysis:
        return 'تحليل الصورة';
      case EventType.strokePrediction:
        return 'السكتة الدماغية';
      case EventType.generalHealth:
        return 'الصحة العامة';
    }
  }

  String _getRiskLevelName(RiskLevel level, bool isArabic) {
    if (!isArabic) {
      switch (level) {
        case RiskLevel.critical:
          return 'Critical';
        case RiskLevel.warning:
          return 'Warning';
        case RiskLevel.info:
          return 'Info';
        case RiskLevel.none:
          return 'Normal';
      }
    }
    switch (level) {
      case RiskLevel.critical:
        return 'حرج';
      case RiskLevel.warning:
        return 'تحذير';
      case RiskLevel.info:
        return 'تنبيه';
      case RiskLevel.none:
        return 'طبيعي';
    }
  }

  HealthEvent? _getWorstEvent(HealthHistoryProvider provider) {
    HealthEvent? worst;
    for (final type in EventType.values) {
      final e = provider.latestFor(type);
      if (e != null) {
        if (worst == null || e.riskScore > worst.riskScore) worst = e;
      }
    }
    return worst;
  }

  Future<void> _explain() async {
    final isArabic = Provider.of<AppSettings>(context, listen: false).locale.languageCode == 'ar';
    final provider = context.read<HealthHistoryProvider>();
    final event = _getWorstEvent(provider);
    if (event == null) {
      setState(() => _error = isArabic
          ? 'لا توجد بيانات صحية بعد. أجرِ فحصاً أولاً.'
          : 'No health data yet. Run a scan first.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    final result = await _service.explain(
      eventType: _getEventTypeName(event.eventType, isArabic),
      riskScore: event.riskScore,
      riskLevel: _getRiskLevelName(event.riskLevel, isArabic),
      notes: event.notes ?? '',
      isArabic: isArabic,
    );

    setState(() {
      _loading = false;
      if (result != null) {
        _result = result;
      } else {
        _error = isArabic
            ? 'تعذر الاتصال بالخادم. تأكد من تشغيل الخادم المحلي.'
            : 'Server connection failed. Make sure the local server is running.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<AppSettings>(context, listen: false).locale.languageCode == 'ar';
    final provider = context.watch<HealthHistoryProvider>();
    final event = _getWorstEvent(provider);

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          leading: Builder(
            builder: (context) {
              final isArabic = Provider.of<AppSettings>(context, listen: false)
                  .locale.languageCode == 'ar';
              return IconButton(
                icon: Icon(
                  isArabic
                      ? Icons.arrow_forward_ios_rounded
                      : Icons.arrow_back_ios_rounded,
                ),
                onPressed: () => Navigator.pop(context),
              );
            },
          ),
          title: Text(isArabic
              ? 'تفسير نتيجة الذكاء الاصطناعي'
              : 'AI Result Explanation'),
          centerTitle: true,
        ),
        floatingActionButton: const ChatbotFAB(),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic
                            ? 'ملخص آخر نتيجة تنبؤ'
                            : 'Latest Prediction Summary',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 10),
                      if (event == null)
                        Text(
                          isArabic ? 'لا توجد بيانات بعد' : 'No data yet',
                          style: const TextStyle(color: Colors.grey),
                        )
                      else ...[
                        _DataRow(
                          isArabic ? 'النوع' : 'Type',
                          _getEventTypeName(event.eventType, isArabic),
                        ),
                        _DataRow(
                          isArabic ? 'درجة الخطر' : 'Risk Score',
                          '${(event.riskScore * 100).toStringAsFixed(0)}%',
                        ),
                        _DataRow(
                          isArabic ? 'المستوى' : 'Level',
                          _getRiskLevelName(event.riskLevel, isArabic),
                        ),
                        if (event.notes != null)
                          _DataRow(
                            isArabic ? 'ملاحظة' : 'Note',
                            event.notes!,
                          ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.psychology_outlined),
                  label: Text(
                    isArabic ? 'فسّر هذه النتيجة 🔍' : 'Explain Result 🔍',
                    style: const TextStyle(fontSize: 16),
                  ),
                  onPressed: _loading ? null : _explain,
                ),
              ),

              const SizedBox(height: 20),

              if (_loading)
                Center(
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 12),
                      Text(
                        isArabic
                            ? 'جاري تفسير النتيجة...'
                            : 'Analyzing result...',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),

              if (_error != null)
                Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(_error!,
                        style: const TextStyle(color: Colors.red)),
                  ),
                ),

              if (_result != null) ...[
                _XaiCard(
                  emoji: '🔍',
                  title: isArabic ? 'العوامل المؤثرة' : 'Key Factors',
                  color: const Color(0xFF4C6FFF),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: ((_result!['factors'] as List?)
                                ?.cast<String>() ??
                            [])
                        .map((f) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.fiber_manual_record,
                                      size: 10,
                                      color: Color(0xFF4C6FFF)),
                                  const SizedBox(width: 6),
                                  Expanded(child: Text(f)),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 12),
                _XaiCard(
                  emoji: '📊',
                  title: isArabic
                      ? 'ماذا تعني النتيجة؟'
                      : 'What does this mean?',
                  color: const Color(0xFF388E3C),
                  child: Text(
                    _result!['meaning'] as String? ?? '',
                    style: const TextStyle(height: 1.6),
                  ),
                ),
                const SizedBox(height: 12),
                _XaiCard(
                  emoji: '⚙️',
                  title: isArabic
                      ? 'كيف تم الحساب؟'
                      : 'How was it calculated?',
                  color: const Color(0xFFF57F17),
                  child: Text(
                    _result!['calculation'] as String? ?? '',
                    style: const TextStyle(height: 1.6),
                  ),
                ),
                const SizedBox(height: 12),
                _XaiCard(
                  emoji: '🎯',
                  title: isArabic ? 'مستوى الثقة' : 'Confidence Level',
                  color: const Color(0xFF9C27B0),
                  child: Text(
                    _result!['confidence'] as String? ?? '',
                    style: const TextStyle(height: 1.6),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final String label;
  final String value;
  const _DataRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Text('$label: ',
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ],
        ),
      );
}

class _XaiCard extends StatelessWidget {
  final String emoji;
  final String title;
  final Color color;
  final Widget child;

  const _XaiCard({
    required this.emoji,
    required this.title,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(title,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}
