import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:diabetes_project/core/providers/nutrition_provider.dart';
import 'package:diabetes_project/features/nutrition/nutrition_service.dart';
import 'package:diabetes_project/main.dart';

class NutritionCard extends StatefulWidget {
  const NutritionCard({super.key});

  @override
  State<NutritionCard> createState() => _NutritionCardState();
}

class _NutritionCardState extends State<NutritionCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NutritionProvider>().loadToday();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isArabic =
        Provider.of<AppSettings>(context).locale.languageCode == 'ar';
    final provider = context.watch<NutritionProvider>();
    final s = provider.summary;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isArabic ? 'التغذية اليومية' : 'Daily Nutrition',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    isArabic
                        ? '${s.mealCount} وجبة'
                        : '${s.mealCount} meals',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _NutRow(
                label: isArabic ? 'سعرات حرارية' : 'Calories',
                value: isArabic
                    ? '${s.totalCalories.toInt()} ك.س'
                    : '${s.totalCalories.toInt()} kcal',
              ),
              _NutRow(
                label: isArabic ? 'كربوهيدرات' : 'Carbs',
                value: '${s.totalCarbs.toStringAsFixed(1)} g',
              ),
              _NutRow(
                label: isArabic ? 'بروتين' : 'Protein',
                value: '${s.totalProtein.toStringAsFixed(1)} g',
              ),
              _NutRow(
                label: isArabic ? 'دهون' : 'Fat',
                value: '${s.totalFat.toStringAsFixed(1)} g',
              ),
              _NutRow(
                label: isArabic ? 'ألياف' : 'Fiber',
                value: '${s.totalFiber.toStringAsFixed(1)} g',
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isArabic
                      ? 'تأثير السكر اليوم:'
                      : 'Sugar impact today:'),
                  _ImpactBadge(
                      impact: s.avgGlucoseImpact, isArabic: isArabic),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                NutritionService.impactAdvice(s.avgGlucoseImpact,
                    isArabic: isArabic),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NutRow extends StatelessWidget {
  final String label;
  final String value;
  const _NutRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.black54)),
            Text(value,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      );
}

class _ImpactBadge extends StatelessWidget {
  final double impact;
  final bool isArabic;
  const _ImpactBadge({required this.impact, required this.isArabic});

  Color _color() {
    if (impact >= 7) return const Color(0xFFD32F2F);
    if (impact >= 5) return const Color(0xFFFFA000);
    if (impact >= 3) return const Color(0xFF1976D2);
    return const Color(0xFF388E3C);
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        NutritionService.impactLabel(impact, isArabic: isArabic),
        style: TextStyle(
            color: color, fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }
}
