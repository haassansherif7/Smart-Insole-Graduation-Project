import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:diabetes_project/core/database/health_event.dart';
import 'package:diabetes_project/core/providers/health_history_provider.dart';
import 'package:diabetes_project/main.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HealthHistoryProvider>();
    final isArabic = Provider.of<AppSettings>(context).locale.languageCode == 'ar';
    final latest = provider.latestFor(EventType.sensorScan)
        ?? provider.latestFor(EventType.imageAnalysis);
    final riskLevel = latest?.riskLevel ?? RiskLevel.none;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
        title: Text(isArabic ? '🚨 تعليمات الطوارئ' : '🚨 Emergency Instructions'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Risk level badge
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _badgeColor(riskLevel),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    _riskIcon(riskLevel),
                    style: const TextStyle(fontSize: 48),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isArabic ? _riskLabelAr(riskLevel) : _riskLabelEn(riskLevel),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Immediate actions
            _buildSection(
              context,
              title: isArabic ? '⚡ افعل الآن فوراً' : '⚡ Do This Now',
              items: isArabic
                  ? _immediateActionsAr(riskLevel)
                  : _immediateActionsEn(riskLevel),
            ),
            const SizedBox(height: 12),
            // Until hospital
            _buildSection(
              context,
              title: isArabic ? '🏥 حتى تصل المستشفى' : '🏥 Until You Reach Hospital',
              items: isArabic
                  ? _untilHospitalAr(riskLevel)
                  : _untilHospitalEn(riskLevel),
            ),
            const SizedBox(height: 12),
            // Prevention tips
            _buildSection(
              context,
              title: isArabic ? '🛡️ للوقاية مستقبلاً' : '🛡️ For Future Prevention',
              items: isArabic ? _preventionAr() : _preventionEn(),
            ),
            const SizedBox(height: 20),
            // Emergency call button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.local_hospital, color: Colors.white),
                label: Text(
                  isArabic ? '📞 اتصل بالإسعاف' : '📞 Call Emergency',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                onPressed: () => _launch('tel:123'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<String> items,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyMedium?.color)),
          const SizedBox(height: 10),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyMedium?.color)),
                    Expanded(
                        child: Text(item,
                            style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: theme.textTheme.bodyMedium?.color))),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Color _badgeColor(RiskLevel l) => l == RiskLevel.critical
      ? Colors.red
      : l == RiskLevel.warning
          ? Colors.orange
          : l == RiskLevel.info
              ? Colors.blue
              : Colors.green;

  String _riskIcon(RiskLevel l) => l == RiskLevel.critical
      ? '🚨'
      : l == RiskLevel.warning
          ? '⚠️'
          : l == RiskLevel.info
              ? 'ℹ️'
              : '✅';

  String _riskLabelAr(RiskLevel l) => l == RiskLevel.critical
      ? 'حالة حرجة'
      : l == RiskLevel.warning
          ? 'تحذير'
          : l == RiskLevel.info
              ? 'تنبيه'
              : 'وضع طبيعي';

  String _riskLabelEn(RiskLevel l) => l == RiskLevel.critical
      ? 'Critical'
      : l == RiskLevel.warning
          ? 'Warning'
          : l == RiskLevel.info
              ? 'Info'
              : 'Normal';

  List<String> _immediateActionsAr(RiskLevel l) {
    if (l == RiskLevel.critical) {
      return [
        'لا تمشِ على القدم المصابة إطلاقاً',
        'نظّف الجرح بمحلول ملحي فوراً',
        'غطِّ الجرح بضمادة نظيفة',
        'اتصل بطبيبك المعالج الآن',
        'اذهب لأقرب طوارئ مستشفى',
      ];
    }
    if (l == RiskLevel.warning) {
      return [
        'قلل الضغط على القدم المصابة',
        'افحص القدم بعناية للبحث عن جروح',
        'نظّف المنطقة وضع ضمادة نظيفة',
        'راجع طبيبك خلال 24 ساعة',
      ];
    }
    return [
      'استمر في مراقبة القدم يومياً',
      'تأكد من ارتداء حذاء مناسب',
      'حافظ على نظافة القدمين',
    ];
  }

  List<String> _immediateActionsEn(RiskLevel l) {
    if (l == RiskLevel.critical) {
      return [
        'Do NOT walk on the affected foot',
        'Clean the wound with saline solution immediately',
        'Cover with a clean sterile bandage',
        'Call your doctor right now',
        'Go to the nearest emergency room',
      ];
    }
    if (l == RiskLevel.warning) {
      return [
        'Reduce pressure on the affected foot',
        'Carefully inspect foot for wounds',
        'Clean area and apply clean bandage',
        'See your doctor within 24 hours',
      ];
    }
    return [
      'Continue daily foot monitoring',
      'Ensure proper diabetic footwear',
      'Maintain foot hygiene',
    ];
  }

  List<String> _untilHospitalAr(RiskLevel l) {
    if (l == RiskLevel.critical) {
      return [
        'ارفع القدم لأعلى لتقليل التورم',
        'لا تضع أي كريمات أو مراهم على الجرح',
        'راقب علامات العدوى: احمرار، تورم، رائحة',
        'لا تأكل أو تشرب إذا كنت ستحتاج لعملية',
      ];
    }
    if (l == RiskLevel.warning) {
      return [
        'ارفع القدم أثناء الجلوس',
        'تجنب المشي الطويل',
        'راقب تغيرات اللون أو الألم',
      ];
    }
    return ['استمر في روتينك اليومي الطبيعي'];
  }

  List<String> _untilHospitalEn(RiskLevel l) {
    if (l == RiskLevel.critical) {
      return [
        'Elevate the foot to reduce swelling',
        'Do not apply creams or ointments to wound',
        'Watch for infection signs: redness, swelling, odor',
        'Do not eat or drink if surgery may be needed',
      ];
    }
    if (l == RiskLevel.warning) {
      return [
        'Elevate foot when sitting',
        'Avoid prolonged walking',
        'Monitor for color changes or increased pain',
      ];
    }
    return ['Continue your normal daily routine'];
  }

  List<String> _preventionAr() => [
        'افحص قدميك كل يوم في نفس الوقت',
        'ارطّب القدمين بكريم مناسب بعد الاستحمام',
        'لا تقص أظافرك قصاً عميقاً',
        'ارتدِ جوارب قطنية بيضاء',
        'حافظ على مستوى السكر ضمن المعدل الطبيعي',
        'لا تمشِ حافي القدمين حتى في المنزل',
      ];

  List<String> _preventionEn() => [
        'Inspect both feet daily at the same time',
        'Moisturize feet with appropriate cream after bathing',
        'Do not cut nails too short',
        'Wear white cotton socks',
        'Keep blood sugar within normal range',
        'Never walk barefoot even indoors',
      ];
}
