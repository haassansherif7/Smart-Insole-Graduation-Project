import 'dart:math';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Food model (self-contained, mirrors nutrition_screen food data)
// ─────────────────────────────────────────────────────────────────────────────

class _WFood {
  final String ar, en;
  final double cal, carbs, protein;
  final int gi;
  const _WFood(this.ar, this.en, this.cal, this.carbs, this.protein, this.gi);
}

const _wFoods = <_WFood>[
  // Proteins
  _WFood('صدر دجاج مشوي', 'Grilled Chicken Breast', 165, 0, 31, 0),
  _WFood('سمك مشوي', 'Grilled Fish', 136, 0, 27, 0),
  _WFood('تونة', 'Tuna', 116, 0, 26, 0),
  _WFood('بيض مسلوق', 'Boiled Egg', 78, 1, 6, 0),
  _WFood('لحم بقر قليل الدهن', 'Lean Beef', 250, 0, 26, 0),
  _WFood('جمبري', 'Shrimp', 85, 0, 18, 0),
  // Carbs
  _WFood('أرز بني', 'Brown Rice', 216, 45, 5, 50),
  _WFood('أرز أبيض', 'White Rice', 204, 44, 4, 72),
  _WFood('شوفان', 'Oats', 193, 33, 7, 55),
  _WFood('خبز قمح كامل', 'Whole Wheat Bread', 81, 15, 4, 51),
  _WFood('خبز أبيض', 'White Bread', 79, 15, 3, 75),
  _WFood('معكرونة', 'Pasta', 220, 43, 8, 50),
  _WFood('بطاطا حلوة', 'Sweet Potato', 86, 20, 2, 44),
  _WFood('بطاطا', 'Potato', 77, 17, 2, 78),
  _WFood('عدس', 'Lentils', 230, 40, 18, 29),
  _WFood('فاصوليا', 'Beans', 127, 23, 9, 24),
  _WFood('فول', 'Fava Beans', 110, 20, 8, 40),
  _WFood('حمص', 'Chickpeas', 164, 27, 9, 28),
  // Vegetables
  _WFood('بروكلي', 'Broccoli', 34, 7, 3, 10),
  _WFood('سبانخ', 'Spinach', 23, 4, 3, 15),
  _WFood('خيار', 'Cucumber', 15, 4, 1, 15),
  _WFood('طماطم', 'Tomato', 18, 4, 1, 30),
  _WFood('خس', 'Lettuce', 15, 3, 1, 10),
  _WFood('جزر', 'Carrot', 41, 10, 1, 39),
  _WFood('كوسة', 'Zucchini', 17, 3, 1, 15),
  _WFood('بصل', 'Onion', 40, 9, 1, 10),
  _WFood('فلفل', 'Bell Pepper', 31, 6, 1, 15),
  _WFood('باذنجان', 'Eggplant', 25, 6, 1, 15),
  // Fruits
  _WFood('تفاحة', 'Apple', 95, 25, 0, 36),
  _WFood('برتقالة', 'Orange', 62, 15, 1, 43),
  _WFood('موزة', 'Banana', 105, 27, 1, 51),
  _WFood('فراولة', 'Strawberry', 32, 8, 1, 41),
  _WFood('كيوي', 'Kiwi', 42, 10, 1, 50),
  _WFood('برقوق', 'Plum', 30, 8, 1, 24),
  // Dairy
  _WFood('حليب قليل الدسم', 'Low Fat Milk', 102, 12, 8, 32),
  _WFood('لبن زبادي', 'Yogurt', 120, 9, 8, 35),
  _WFood('جبن أبيض', 'White Cheese', 75, 1, 5, 0),
  _WFood('لبنة', 'Labneh', 35, 2, 3, 0),
  // Nuts & Fats
  _WFood('لوز', 'Almonds', 173, 6, 6, 0),
  _WFood('جوز', 'Walnuts', 196, 4, 5, 0),
  _WFood('أفوكادو', 'Avocado', 160, 9, 2, 10),
];

const _wHealingAr = {'سمك مشوي', 'بيض مسلوق', 'بروكلي', 'سبانخ', 'لوز'};

// ─────────────────────────────────────────────────────────────────────────────
// Day model
// ─────────────────────────────────────────────────────────────────────────────

class _WDayPlan {
  final String nameAr, nameEn;
  final List<_WFood> breakfast, lunch, dinner;

  const _WDayPlan({
    required this.nameAr,
    required this.nameEn,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
  });

  double get totalCal =>
      [...breakfast, ...lunch, ...dinner].fold(0.0, (s, f) => s + f.cal);
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class WeeklyPlanScreen extends StatefulWidget {
  final double weight;
  final String bloodSugar;
  final String activity;
  final String goal;
  final List<String> disliked;
  final String diet;
  final bool isArabic;
  final bool isCritical;

  const WeeklyPlanScreen({
    super.key,
    required this.weight,
    required this.bloodSugar,
    required this.activity,
    required this.goal,
    required this.disliked,
    required this.diet,
    required this.isArabic,
    required this.isCritical,
  });

  @override
  State<WeeklyPlanScreen> createState() => _WeeklyPlanScreenState();
}

class _WeeklyPlanScreenState extends State<WeeklyPlanScreen> {
  List<_WDayPlan> _plan = [];
  int _seed = 0;

  @override
  void initState() {
    super.initState();
    _seed = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _generate();
  }

  // ── Food pool ──────────────────────────────────────────────────────────────

  List<_WFood> _buildPool() {
    final strictGi = widget.bloodSugar == 'high' ||
        widget.bloodSugar == 'diabetic' ||
        widget.isCritical;
    return _wFoods.where((f) {
      if (widget.disliked.contains(f.ar)) return false;
      if (strictGi && f.gi > 55 && f.gi != 0) return false;
      if (widget.diet == 'vegetarian' &&
          {'صدر دجاج مشوي', 'سمك مشوي', 'تونة', 'لحم بقر قليل الدهن', 'جمبري'}
              .contains(f.ar)) { return false; }
      return true;
    }).toList();
  }

  _WFood _pick(List<_WFood> src, Random rng) => src[rng.nextInt(src.length)];

  _WFood _pickH(List<_WFood> src, Random rng) {
    final healing = src.where((f) => _wHealingAr.contains(f.ar)).toList();
    if (healing.isNotEmpty) return healing[rng.nextInt(healing.length)];
    return _pick(src, rng);
  }

  List<_WFood> _safe(List<_WFood> l, List<_WFood> pool) =>
      l.isEmpty ? pool : l;

  List<_WFood> _mealFor(String type, Random rng, List<_WFood> pool) {
    if (pool.isEmpty) return [_wFoods.first];

    final proteins = pool.where((f) => f.protein >= 6).toList();
    final carbs =
        pool.where((f) => f.carbs >= 10 && f.carbs <= 45).toList();
    final vegs = pool.where((f) => f.cal < 50 && f.carbs < 10).toList();
    final fruits =
        pool.where((f) => f.cal < 110 && f.carbs > 5).toList();

    _WFood pp(List<_WFood> l) => widget.isCritical
        ? _pickH(_safe(l, pool), rng)
        : _pick(_safe(l, pool), rng);
    _WFood pv(List<_WFood> l) => widget.isCritical
        ? _pickH(_safe(l, pool), rng)
        : _pick(_safe(l, pool), rng);

    switch (type) {
      case 'breakfast':
        return [_pick(_safe(carbs, pool), rng), pp(proteins)];
      case 'lunch':
        return [pp(proteins), _pick(_safe(carbs, pool), rng), pv(vegs)];
      case 'dinner':
        return [pp(proteins), pv(vegs), _pick(_safe(fruits, pool), rng)];
      default:
        return [_pick(pool, rng)];
    }
  }

  // ── Generation ─────────────────────────────────────────────────────────────

  void _generate() {
    const dayNamesAr = [
      'السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'
    ];
    const dayNamesEn = [
      'Saturday', 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'
    ];

    final pool = _buildPool();
    setState(() {
      _plan = List.generate(7, (i) {
        final rng = Random(_seed + i * 997);
        return _WDayPlan(
          nameAr: dayNamesAr[i],
          nameEn: dayNamesEn[i],
          breakfast: _mealFor('breakfast', rng, pool),
          lunch: _mealFor('lunch', rng, pool),
          dinner: _mealFor('dinner', rng, pool),
        );
      });
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isArabic = widget.isArabic;
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isArabic ? 'الخطة الأسبوعية' : 'Weekly Plan'),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: Text(
                  isArabic
                      ? '🔄 توليد خطة أسبوعية جديدة'
                      : '🔄 Generate New Weekly Plan',
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: const Color(0xFF4C6FFF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  _seed += 100;
                  _generate();
                },
              ),
            ),
            if (widget.isCritical)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Text('🚨', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isArabic
                              ? 'وضع الخطر الحرج: الخطة تُركز على أطعمة الشفاء'
                              : 'Critical risk mode: plan prioritizes healing foods',
                          style: TextStyle(
                              fontSize: 12, color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                itemCount: _plan.length,
                itemBuilder: (_, i) => _buildDayCard(_plan[i], isArabic),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCard(_WDayPlan day, bool isArabic) {
    final totalCal = day.totalCal.toInt();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ExpansionTile(
        tilePadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          isArabic ? day.nameAr : day.nameEn,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          '${isArabic ? 'السعرات الإجمالية' : 'Total calories'}: $totalCal kcal',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMealSection(
                  isArabic ? '🌅 الإفطار' : '🌅 Breakfast',
                  day.breakfast,
                  isArabic,
                ),
                const Divider(height: 20),
                _buildMealSection(
                  isArabic ? '☀️ الغداء' : '☀️ Lunch',
                  day.lunch,
                  isArabic,
                ),
                const Divider(height: 20),
                _buildMealSection(
                  isArabic ? '🌙 العشاء' : '🌙 Dinner',
                  day.dinner,
                  isArabic,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealSection(String title, List<_WFood> foods, bool isArabic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        ...foods.map((f) {
          final isHealing = _wHealingAr.contains(f.ar);
          final giColor = f.gi == 0
              ? Colors.grey
              : f.gi < 55
                  ? Colors.green
                  : f.gi <= 70
                      ? Colors.orange
                      : Colors.red;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration:
                      BoxDecoration(color: giColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(isArabic ? f.ar : f.en,
                      style: const TextStyle(fontSize: 13)),
                ),
                if (widget.isCritical && isHealing)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Text(
                      isArabic ? '💚 شفاء' : '💚 Healing',
                      style: TextStyle(
                          fontSize: 9,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                Text('${f.cal.toInt()} kcal',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey)),
              ],
            ),
          );
        }),
      ],
    );
  }
}
