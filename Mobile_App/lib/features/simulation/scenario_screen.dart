import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:diabetes_project/core/database/health_event.dart';
import 'package:diabetes_project/core/providers/health_history_provider.dart';
import 'package:diabetes_project/features/simulation/scenario_service.dart';
import 'package:diabetes_project/main.dart';
import 'package:diabetes_project/core/widgets/chatbot_fab.dart';

class ScenarioScreen extends StatefulWidget {
  const ScenarioScreen({super.key});

  @override
  State<ScenarioScreen> createState() => _ScenarioScreenState();
}

class _ScenarioScreenState extends State<ScenarioScreen> {
  final _service = ScenarioService();
  bool _loading = false;
  ScenarioResult? _result;
  String? _error;

  Future<void> _simulate() async {
    final isArabic = Provider.of<AppSettings>(context, listen: false).locale.languageCode == 'ar';

    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    final provider = context.read<HealthHistoryProvider>();
    final imageEvent = provider.latestFor(EventType.imageAnalysis);
    final footRisk =
        ((imageEvent?.riskScore ?? 0) * 100).toStringAsFixed(0);
    final grade = imageEvent?.notes ??
        (isArabic ? 'غير محدد' : 'Not specified');
    final lastScan = imageEvent != null
        ? _formatDate(imageEvent.timestamp)
        : (isArabic ? 'لا يوجد فحص' : 'No scan');

    final result = await _service.simulate(
      {
        'footRisk': footRisk,
        'lastScan': lastScan,
        'grade': grade,
      },
      isArabic: isArabic,
    );

    setState(() {
      _loading = false;
      if (result != null) {
        _result = result;
      } else {
        _error = isArabic
            ? 'تعذر الاتصال. تحقق من اتصال الإنترنت وحاول مجدداً.'
            : 'Connection failed. Check your connection and try again.';
      }
    });
  }

  String _formatDate(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year}';

  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<AppSettings>(context, listen: false).locale.languageCode == 'ar';
    final provider = context.watch<HealthHistoryProvider>();
    final imageEvent = provider.latestFor(EventType.imageAnalysis);
    final footRisk =
        ((imageEvent?.riskScore ?? 0) * 100).toStringAsFixed(0);
    final grade = imageEvent?.notes ??
        (isArabic ? 'غير محدد' : 'Not specified');

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
              ? 'محاكاة السيناريوهات المستقبلية'
              : 'Future Scenario Simulation'),
          centerTitle: true,
        ),
        floatingActionButton: const ChatbotFAB(),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient data card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic
                            ? 'بيانات المريض الحالية'
                            : 'Current Patient Data',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 10),
                      _DataRow(
                        isArabic ? 'درجة خطر القدم' : 'Foot Risk Score',
                        '$footRisk%',
                      ),
                      _DataRow(
                        isArabic ? 'درجة القرحة' : 'Ulcer Grade',
                        grade,
                      ),
                      _DataRow(
                        isArabic ? 'آخر فحص' : 'Last Scan',
                        imageEvent != null
                            ? _formatDate(imageEvent.timestamp)
                            : (isArabic ? 'لا يوجد فحص' : 'No scan'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.auto_fix_high),
                  label: Text(
                    isArabic ? 'محاكاة المستقبل 🔮' : 'Simulate Future 🔮',
                    style: const TextStyle(fontSize: 16),
                  ),
                  onPressed: _loading ? null : _simulate,
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
                            ? 'جاري تحليل السيناريوهات...'
                            : 'Analyzing scenarios...',
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
                _ScenarioCard(
                  title: isArabic ? 'السيناريو الأسوأ' : 'Worst Scenario',
                  subtitle: isArabic
                      ? 'في حال عدم الالتزام'
                      : 'If non-compliant',
                  icon: Icons.warning_rounded,
                  color: Colors.red,
                  details: _result!.worst,
                  isArabic: isArabic,
                ),
                const SizedBox(height: 12),
                _ScenarioCard(
                  title: isArabic ? 'السيناريو المتوسط' : 'Medium Scenario',
                  subtitle: isArabic
                      ? 'مع التزام جزئي'
                      : 'With partial compliance',
                  icon: Icons.trending_flat,
                  color: Colors.orange,
                  details: _result!.medium,
                  isArabic: isArabic,
                ),
                const SizedBox(height: 12),
                _ScenarioCard(
                  title: isArabic ? 'السيناريو الأفضل' : 'Best Scenario',
                  subtitle: isArabic
                      ? 'مع الالتزام الكامل'
                      : 'With full compliance',
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                  details: _result!.best,
                  isArabic: isArabic,
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
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      );
}

class _ScenarioCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final ScenarioDetails details;
  final bool isArabic;

  const _ScenarioCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.details,
    required this.isArabic,
  });

  @override
  State<_ScenarioCard> createState() => _ScenarioCardState();
}

class _ScenarioCardState extends State<_ScenarioCard> {
  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<AppSettings>(context, listen: false).locale.languageCode == 'ar';

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: widget.color.withValues(alpha: 0.4)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          leading: Icon(widget.icon, color: widget.color),
          title: Text(widget.title,
              style: TextStyle(
                  color: widget.color, fontWeight: FontWeight.bold)),
          subtitle: Text(widget.subtitle,
              style: const TextStyle(fontSize: 12)),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  _SectionLabel(
                      isArabic ? 'خلال أسبوع' : 'Within a week'),
                  const SizedBox(height: 4),
                  Text(widget.details.week,
                      style: const TextStyle(height: 1.5)),
                  const SizedBox(height: 12),
                  _SectionLabel(
                      isArabic ? 'خلال شهر' : 'Within a month'),
                  const SizedBox(height: 4),
                  Text(widget.details.month,
                      style: const TextStyle(height: 1.5)),
                  if (widget.details.tips.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _SectionLabel(
                        isArabic ? 'التوصيات' : 'Recommendations'),
                    const SizedBox(height: 6),
                    ...widget.details.tips.map(
                      (t) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.arrow_left,
                                color: widget.color, size: 18),
                            Expanded(child: Text(t)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Color(0xFF4C6FFF)));
}
