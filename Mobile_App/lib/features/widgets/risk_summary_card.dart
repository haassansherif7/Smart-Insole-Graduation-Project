import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:diabetes_project/core/database/health_event.dart';
import 'package:diabetes_project/core/providers/health_history_provider.dart';
import 'package:diabetes_project/main.dart';

class RiskSummaryCard extends StatelessWidget {
  const RiskSummaryCard({super.key});

  static const _texts = {
    'title': {'ar': 'ملخص مستوى الخطر', 'en': 'Risk Level Summary'},
  };

  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<AppSettings>(context).locale.languageCode == 'ar';
    final lang = isArabic ? 'ar' : 'en';
    final provider = context.watch<HealthHistoryProvider>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _texts['title']![lang]!,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...EventType.values.map(
              (type) => _TypeRow(type: type, provider: provider),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeRow extends StatelessWidget {
  final EventType type;
  final HealthHistoryProvider provider;

  const _TypeRow({required this.type, required this.provider});

  static const _texts = {
    'noData': {'ar': 'لا توجد بيانات', 'en': 'No data'},
  };

  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<AppSettings>(context).locale.languageCode == 'ar';
    final lang = isArabic ? 'ar' : 'en';
    final event = provider.latestFor(type);
    final score = event?.riskScore ?? 0.0;
    final level = event?.riskLevel ?? RiskLevel.none;
    final color = _color(level);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(_label(type, lang))),
          if (event == null)
            Text(
              _texts['noData']![lang]!,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            )
          else ...[
            SizedBox(
              width: 120,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: score,
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(score * 100).toInt()}%',
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }

  Color _color(RiskLevel level) => switch (level) {
        RiskLevel.critical => const Color(0xFFD32F2F),
        RiskLevel.warning => const Color(0xFFFFA000),
        RiskLevel.info => const Color(0xFF1976D2),
        RiskLevel.none => const Color(0xFF388E3C),
      };

  String _label(EventType type, String lang) => switch (type) {
        EventType.sensorScan =>
          lang == 'ar' ? 'مسح الاستشعار' : 'Sensor Scan',
        EventType.imageAnalysis =>
          lang == 'ar' ? 'تحليل الصورة' : 'Image Analysis',
        EventType.strokePrediction =>
          lang == 'ar' ? 'خطر السكتة' : 'Stroke Risk',
        EventType.generalHealth =>
          lang == 'ar' ? 'الصحة العامة' : 'General Health',
      };
}
