import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:diabetes_project/core/providers/health_history_provider.dart';
import 'package:diabetes_project/core/providers/nutrition_provider.dart';
import 'package:diabetes_project/features/nutrition/nutrition_screen.dart';
import 'package:diabetes_project/features/reports/report_screen.dart';
import 'package:diabetes_project/features/simulation/scenario_screen.dart';
import 'package:diabetes_project/features/xai/xai_screen.dart';
import 'package:diabetes_project/features/widgets/alert_banner.dart';
import 'package:diabetes_project/features/widgets/risk_summary_card.dart';
import 'package:diabetes_project/features/widgets/trend_chart.dart';
import 'package:diabetes_project/main.dart';
import 'package:diabetes_project/core/widgets/chatbot_fab.dart';
import 'package:diabetes_project/features/emergency/emergency_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _texts = {
    'title': {'ar': 'لوحة الصحة', 'en': 'Health Dashboard'},
    'error': {'ar': 'خطأ', 'en': 'Error'},
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isArabic = Provider.of<AppSettings>(context, listen: false).locale.languageCode == 'ar';
      context.read<HealthHistoryProvider>().loadDashboardData(isArabic: isArabic);
      context.read<NutritionProvider>().loadToday();
    });
  }

  Future<void> _refresh() async {
    final isArabic = Provider.of<AppSettings>(context, listen: false).locale.languageCode == 'ar';
    await Future.wait([
      context.read<HealthHistoryProvider>().loadDashboardData(isArabic: isArabic),
      context.read<NutritionProvider>().loadToday(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<AppSettings>(context).locale.languageCode == 'ar';
    final lang = isArabic ? 'ar' : 'en';
    final historyProvider = context.watch<HealthHistoryProvider>();

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          centerTitle: true,
          title: Text(isArabic ? 'لوحة الصحة' : 'Health Dashboard'),
          leading: IconButton(
            icon: Icon(
              isArabic
                  ? Icons.arrow_forward_ios_rounded
                  : Icons.arrow_back_ios_rounded,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => historyProvider.loadDashboardData(
                isArabic: isArabic,
              ),
            ),
          ],
        ),
        floatingActionButton: const ChatbotFAB(),
        body: historyProvider.loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    const AlertBanner(),
                    if (historyProvider.error != null)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          '${_texts['error']![lang]!}: ${historyProvider.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Column(
                        children: [
                          RiskSummaryCard(),
                          SizedBox(height: 12),
                          TrendChart(),
                          SizedBox(height: 12),
                          _QuickActions(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  static const _texts = {
    'title': {'ar': 'إجراءات سريعة', 'en': 'Quick Actions'},
    'logMeal': {'ar': 'التغذية الذكية ', 'en': 'Smart Nutrition Planning'},
    'nutritionLog': {'ar': 'سجل التغذية', 'en': 'Nutrition Log'},
    'scenario': {'ar': 'التوقعات المستقبلية  ', 'en': 'Future Prediction '},
    'xai': {'ar': 'تفسير النتيجة ', 'en': 'Explain Result '},
    'report': {'ar': 'التقرير الطبي', 'en': 'Medical Report'},
    'emergency': {'ar': '🚨 تعليمات الطوارئ', 'en': '🚨 Emergency'},
  };

  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<AppSettings>(context).locale.languageCode == 'ar';
    final lang = isArabic ? 'ar' : 'en';

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
            Row(
              children: [
                Expanded(
                  child: _ActionBtn(
                    icon: Icons.restaurant_menu,
                    label: _texts['logMeal']![lang]!,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider.value(
                                value: context.read<NutritionProvider>(),
                                child: const NutritionScreen(),
                              )),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionBtn(
                    icon: Icons.auto_fix_high,
                    label: _texts['scenario']![lang]!,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ScenarioScreen()),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _ActionBtn(
                    icon: Icons.psychology_outlined,
                    label: _texts['xai']![lang]!,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const XaiScreen()),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionBtn(
                    icon: Icons.picture_as_pdf,
                    label: _texts['report']![lang]!,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ReportScreen()),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.emergency, color: Colors.white),
                label: Text(
                  _texts['emergency']![lang]!,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EmergencyScreen()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF4C6FFF).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF4C6FFF)),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF4C6FFF)),
            ),
          ],
        ),
      ),
    );
  }
}
