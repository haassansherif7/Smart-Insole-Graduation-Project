import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:diabetes_project/core/alerts/alert_engine.dart';
import 'package:diabetes_project/core/providers/health_history_provider.dart';
import 'package:diabetes_project/core/providers/nutrition_provider.dart';
import 'package:diabetes_project/features/nutrition/nutrition_service.dart';
import 'package:diabetes_project/main.dart';
import 'package:diabetes_project/features/nutrition/weekly_plan_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Food database (kept from original)
// ─────────────────────────────────────────────────────────────────────────────

const _allFoods = <_FoodData>[
  // Proteins
  _FoodData('صدر دجاج مشوي', 'Grilled Chicken Breast', 165, 0, 31, 3.6, 0),
  _FoodData('سمك مشوي', 'Grilled Fish', 136, 0, 27, 3, 0),
  _FoodData('تونة', 'Tuna', 116, 0, 26, 1, 0),
  _FoodData('بيض مسلوق', 'Boiled Egg', 78, 1, 6, 5, 0),
  _FoodData('لحم بقر قليل الدهن', 'Lean Beef', 250, 0, 26, 15, 0),
  _FoodData('جمبري', 'Shrimp', 85, 0, 18, 1, 0),
  // Carbs
  _FoodData('أرز بني', 'Brown Rice (100g)', 216, 45, 5, 2, 50),
  _FoodData('أرز أبيض', 'White Rice (100g)', 204, 44, 4, 0.5, 72),
  _FoodData('شوفان', 'Oats (50g)', 193, 33, 7, 3.5, 55),
  _FoodData('خبز قمح كامل', 'Whole Wheat Bread (slice)', 81, 15, 4, 1, 51),
  _FoodData('خبز أبيض', 'White Bread (slice)', 79, 15, 3, 1, 75),
  _FoodData('معكرونة', 'Pasta (100g)', 220, 43, 8, 1.5, 50),
  _FoodData('بطاطا حلوة', 'Sweet Potato (100g)', 86, 20, 2, 0.1, 44),
  _FoodData('بطاطا', 'Potato (100g)', 77, 17, 2, 0.1, 78),
  _FoodData('عدس', 'Lentils (100g)', 230, 40, 18, 1, 29),
  _FoodData('فاصوليا', 'Beans (100g)', 127, 23, 9, 0.5, 24),
  _FoodData('فول', 'Fava Beans (100g)', 110, 20, 8, 0.5, 40),
  _FoodData('حمص', 'Chickpeas (100g)', 164, 27, 9, 2.6, 28),
  // Vegetables
  _FoodData('بروكلي', 'Broccoli (100g)', 34, 7, 3, 0.4, 10),
  _FoodData('سبانخ', 'Spinach (100g)', 23, 4, 3, 0.4, 15),
  _FoodData('خيار', 'Cucumber (100g)', 15, 4, 1, 0.1, 15),
  _FoodData('طماطم', 'Tomato (100g)', 18, 4, 1, 0.2, 30),
  _FoodData('خس', 'Lettuce (100g)', 15, 3, 1, 0.2, 10),
  _FoodData('جزر', 'Carrot (100g)', 41, 10, 1, 0.2, 39),
  _FoodData('كوسة', 'Zucchini (100g)', 17, 3, 1, 0.3, 15),
  _FoodData('بصل', 'Onion (100g)', 40, 9, 1, 0.1, 10),
  _FoodData('فلفل', 'Bell Pepper (100g)', 31, 6, 1, 0.3, 15),
  _FoodData('باذنجان', 'Eggplant (100g)', 25, 6, 1, 0.2, 15),
  // Fruits
  _FoodData('تفاحة', 'Apple (medium)', 95, 25, 0.5, 0.3, 36),
  _FoodData('برتقالة', 'Orange (medium)', 62, 15, 1.2, 0.2, 43),
  _FoodData('موزة', 'Banana (medium)', 105, 27, 1.3, 0.4, 51),
  _FoodData('بطيخ', 'Watermelon (100g)', 30, 8, 0.6, 0.2, 72),
  _FoodData('عنب', 'Grapes (100g)', 67, 17, 0.6, 0.4, 59),
  _FoodData('مانجو', 'Mango (100g)', 60, 15, 0.8, 0.4, 51),
  _FoodData('فراولة', 'Strawberry (100g)', 32, 8, 0.7, 0.3, 41),
  _FoodData('تمر', 'Dates (1 piece)', 23, 6, 0.2, 0, 42),
  _FoodData('كيوي', 'Kiwi (medium)', 42, 10, 0.8, 0.4, 50),
  _FoodData('برقوق', 'Plum (medium)', 30, 8, 0.5, 0.2, 24),
  // Dairy
  _FoodData('حليب قليل الدسم', 'Low Fat Milk (200ml)', 102, 12, 8, 2.5, 32),
  _FoodData('لبن زبادي', 'Yogurt (200ml)', 120, 9, 8, 3.5, 35),
  _FoodData('جبن أبيض', 'White Cheese (30g)', 75, 1, 5, 6, 0),
  _FoodData('لبنة', 'Labneh (2 tbsp)', 35, 2, 3, 2, 0),
  // Fats & Nuts
  _FoodData('زيت زيتون', 'Olive Oil (1 tbsp)', 119, 0, 0, 14, 0),
  _FoodData('لوز', 'Almonds (30g)', 173, 6, 6, 15, 0),
  _FoodData('جوز', 'Walnuts (30g)', 196, 4, 5, 19, 0),
  _FoodData('أفوكادو', 'Avocado (100g)', 160, 9, 2, 15, 10),
  _FoodData('فول سوداني', 'Peanuts (30g)', 166, 6, 7, 14, 14),
  // Drinks
  _FoodData('ماء', 'Water', 0, 0, 0, 0, 0),
  _FoodData('شاي أخضر', 'Green Tea', 2, 0, 0, 0, 0),
  _FoodData('قهوة بدون سكر', 'Black Coffee', 5, 0, 0, 0, 0),
  _FoodData('عصير برتقال طازج', 'Fresh OJ (200ml)', 88, 21, 1.3, 0.4, 50),
];

class _FoodData {
  final String nameAr;
  final String nameEn;
  final double cal;
  final double carbs;
  final double protein;
  final double fat;
  final int gi;
  const _FoodData(
      this.nameAr, this.nameEn, this.cal, this.carbs, this.protein, this.fat, this.gi);
}

// ─────────────────────────────────────────────────────────────────────────────
// SharedPreferences keys
// ─────────────────────────────────────────────────────────────────────────────

const _kWeight = 'nx_weight';
const _kBloodSugar = 'nx_blood_sugar';
const _kActivity = 'nx_activity';
const _kGoal = 'nx_goal';
const _kConditions = 'nx_conditions';
const _kDiet = 'nx_diet';
const _kLiked = 'nx_liked';
const _kDisliked = 'nx_disliked';

// ─────────────────────────────────────────────────────────────────────────────
// GI helpers
// ─────────────────────────────────────────────────────────────────────────────

Color _giColor(int gi) => gi == 0
    ? Colors.grey
    : gi < 55
        ? Colors.green
        : gi <= 70
            ? Colors.orange
            : Colors.red;

String _giLabel(int gi) => gi == 0
    ? 'GI: -'
    : gi < 55
        ? 'GI: $gi ✅'
        : gi <= 70
            ? 'GI: $gi ⚠️'
            : 'GI: $gi 🔴';

// ─────────────────────────────────────────────────────────────────────────────
// Planned meal model
// ─────────────────────────────────────────────────────────────────────────────

class _PlannedMeal {
  final String typeKey;
  List<_FoodData> foods;
  double get totalCal => foods.fold(0, (s, f) => s + f.cal);
  double get totalCarbs => foods.fold(0, (s, f) => s + f.carbs);
  double get totalProtein => foods.fold(0, (s, f) => s + f.protein);
  int get maxGi => foods.fold(0, (s, f) => f.gi > s ? f.gi : s);
  _PlannedMeal(this.typeKey, this.foods);
}

// ─────────────────────────────────────────────────────────────────────────────
// Main screen
// ─────────────────────────────────────────────────────────────────────────────

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen>
    with SingleTickerProviderStateMixin {
  static const _targetCarbs = 225.0;
  static const _targetProtein = 75.0;
  static const _targetFat = 65.0;

  late TabController _tabController;

  // Profile
  Set<String> _conditions = {};
  String _diet = 'mixed';
  List<String> _liked = [];
  List<String> _disliked = [];

  // Tab 1 patient inputs
  double _weight = 70;
  String _bloodSugar = 'diabetic';
  String _activity = 'light';
  String _goal = 'control_sugar';

  // Tab 1 plan
  List<_PlannedMeal> _plan = [];
  bool _planGenerated = false;
  bool _isCritical = false;
  int _tabIndex = 0;

  static const _healingFoodNames = {
    'سمك مشوي', 'بيض مسلوق', 'بروكلي', 'سبانخ', 'لوز',
  };

  // Tab 4 reminders
  final Map<int, bool> _remindersOn = {0: false, 1: false, 2: false, 3: false, 4: false};
  final _notifPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() => _tabIndex = _tabController.index);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<NutritionProvider>().loadToday();
      await _loadProfile();
      await _loadReminderStates();
      await _initNotifications();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Notifications ──────────────────────────────────────────────────────────

  Future<void> _initNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _notifPlugin.initialize(
      const InitializationSettings(android: android),
    );
  }

  Future<void> _toggleReminder(int id, bool on, bool isArabic) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminder_$id', on);
    setState(() => _remindersOn[id] = on);

    if (on) {
      final titles = isArabic
          ? ['تذكير الإفطار', 'تذكير الغداء', 'تذكير العشاء', 'تذكير الماء', 'تذكير الدواء']
          : ['Breakfast Reminder', 'Lunch Reminder', 'Dinner Reminder', 'Water Reminder', 'Medication Reminder'];
      final bodies = isArabic
          ? ['حان وقت الإفطار الصحي!', 'حان وقت الغداء!', 'حان وقت العشاء!', 'اشرب كوب ماء الآن!', 'لا تنسَ دواءك!']
          : ['Time for a healthy breakfast!', 'Time for lunch!', 'Time for dinner!', 'Drink a glass of water now!', 'Don\'t forget your medication!'];
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'nutrition_reminders',
          'Nutrition Reminders',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      );
      await _notifPlugin.periodicallyShow(
        id,
        titles[id],
        bodies[id],
        RepeatInterval.daily,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } else {
      await _notifPlugin.cancel(id);
    }
  }

  Future<void> _loadReminderStates() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (int i = 0; i < 5; i++) {
        _remindersOn[i] = prefs.getBool('reminder_$i') ?? false;
      }
    });
  }

  // ── Profile persistence ────────────────────────────────────────────────────

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _conditions = (prefs.getStringList(_kConditions) ?? []).toSet();
      _diet = prefs.getString(_kDiet) ?? 'mixed';
      _liked = prefs.getStringList(_kLiked) ?? [];
      _disliked = prefs.getStringList(_kDisliked) ?? [];
      _weight = (prefs.getDouble(_kWeight) ?? 70).clamp(40, 150);
      _bloodSugar = prefs.getString(_kBloodSugar) ?? 'diabetic';
      _activity = prefs.getString(_kActivity) ?? 'light';
      _goal = prefs.getString(_kGoal) ?? 'control_sugar';
    });
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kConditions, _conditions.toList());
    await prefs.setString(_kDiet, _diet);
    await prefs.setStringList(_kLiked, _liked);
    await prefs.setStringList(_kDisliked, _disliked);
    await prefs.setDouble(_kWeight, _weight);
    await prefs.setString(_kBloodSugar, _bloodSugar);
    await prefs.setString(_kActivity, _activity);
    await prefs.setString(_kGoal, _goal);
  }

  // ── Plan generation ────────────────────────────────────────────────────────

  double get _calTarget {
    double base = _weight * 25;
    if (_activity == 'sedentary') base *= 1.2;
    if (_activity == 'light') base *= 1.375;
    if (_activity == 'moderate') base *= 1.55;
    if (_activity == 'active') base *= 1.725;
    if (_goal == 'lose_weight') base *= 0.80;
    if (_goal == 'wound_healing') base *= 1.10;
    return base;
  }

  List<_FoodData> get _pool {
    final strictGi = _bloodSugar == 'high' || _bloodSugar == 'diabetic' || _isCritical;
    return _allFoods.where((f) {
      if (_disliked.contains(f.nameAr)) return false;
      if (strictGi && f.gi > 55 && f.gi != 0) return false;
      if (_diet == 'vegetarian' &&
          ['صدر دجاج مشوي', 'سمك مشوي', 'تونة', 'لحم بقر قليل الدهن', 'جمبري']
              .contains(f.nameAr)) { return false; }
      return true;
    }).toList();
  }

  _FoodData _pick(List<_FoodData> src, Random rng) => src[rng.nextInt(src.length)];

  _FoodData _pickCritical(List<_FoodData> src, Random rng) {
    final healing = src.where((f) => _healingFoodNames.contains(f.nameAr)).toList();
    if (healing.isNotEmpty) return healing[rng.nextInt(healing.length)];
    return src[rng.nextInt(src.length)];
  }

  List<_FoodData> _mealsForType(String type, Random rng) {
    final pool = _pool;
    if (pool.isEmpty) return [_allFoods.first];

    final proteins = pool.where((f) => f.protein >= 6).toList();
    final carbs = pool.where((f) => f.carbs >= 10 && f.carbs <= 45).toList();
    final vegs = pool.where((f) => f.cal < 50 && f.carbs < 10).toList();
    final fruits = pool.where((f) => f.cal < 110 && f.carbs > 5).toList();

    List<_FoodData> safe(List<_FoodData> l) => l.isEmpty ? pool : l;
    _FoodData pp(List<_FoodData> l) =>
        _isCritical ? _pickCritical(safe(l), rng) : _pick(safe(l), rng);
    _FoodData pv(List<_FoodData> l) =>
        _isCritical ? _pickCritical(safe(l), rng) : _pick(safe(l), rng);

    switch (type) {
      case 'breakfast':
        final foods = [_pick(safe(carbs), rng)];
        if (_goal == 'wound_healing' || _goal == 'high_protein') {
          foods.add(pp(proteins));
        } else {
          foods.add(_pick(safe(fruits), rng));
        }
        return foods;
      case 'snack1':
        return [_pick(safe(fruits), rng), pv(vegs)];
      case 'lunch':
        final foods = [pp(proteins), _pick(safe(carbs), rng)];
        foods.add(pv(vegs));
        if (_goal == 'wound_healing') foods.add(pp(proteins));
        return foods;
      case 'snack2':
        return [pp(proteins)];
      case 'dinner':
        return [pp(proteins), pv(vegs)];
      default:
        return [_pick(pool, rng)];
    }
  }

  void _generatePlan() {
    final alert = context.read<HealthHistoryProvider>().currentAlert;
    final rng = Random();
    setState(() {
      _isCritical = alert?.level == AlertLevel.critical;
      _plan = [
        _PlannedMeal('breakfast', _mealsForType('breakfast', rng)),
        _PlannedMeal('snack1', _mealsForType('snack1', rng)),
        _PlannedMeal('lunch', _mealsForType('lunch', rng)),
        _PlannedMeal('snack2', _mealsForType('snack2', rng)),
        _PlannedMeal('dinner', _mealsForType('dinner', rng)),
      ];
      _planGenerated = true;
    });
  }

  void _regenerateMeal(int index) {
    final rng = Random();
    setState(() {
      _plan[index].foods = _mealsForType(_plan[index].typeKey, rng);
    });
  }

  void _swapFood(int mealIdx, int foodIdx) {
    final rng = Random();
    final pool = _pool;
    if (pool.isEmpty) return;
    setState(() {
      _plan[mealIdx].foods[foodIdx] = pool[rng.nextInt(pool.length)];
    });
  }

  // ── Nutrition score ────────────────────────────────────────────────────────

  int _computeScore() {
    if (!_planGenerated || _plan.isEmpty) return 0;

    final allFoods = _plan.expand((m) => m.foods).toList();
    final totalCal = allFoods.fold(0.0, (s, f) => s + f.cal);
    final totalProtein = allFoods.fold(0.0, (s, f) => s + f.protein);
    final nonZeroGi = allFoods.where((f) => f.gi > 0).toList();
    final avgGi = nonZeroGi.isEmpty
        ? 0
        : nonZeroGi.fold(0, (s, f) => s + f.gi) ~/ nonZeroGi.length;

    int score = 0;

    // GI score (40 pts)
    if (avgGi < 55) {
      score += 40;
    } else if (avgGi < 65) {
      score += 25;
    } else {
      score += 10;
    }

    // Protein adequacy (20 pts)
    if (totalProtein > 50) {
      score += 20;
    } else if (totalProtein > 30) {
      score += 10;
    }

    // Variety: unique categories (20 pts)
    final categories = <String>{};
    for (final f in allFoods) {
      if (f.protein > 10) categories.add('protein');
      if (f.carbs > 10) categories.add('carb');
      if (f.cal < 50 && f.carbs < 10) categories.add('veg');
      if (f.cal < 110 && f.carbs > 5 && f.protein < 5) categories.add('fruit');
      if (f.fat > 10) categories.add('fat');
    }
    if (categories.length >= 4) { score += 20; }
    else if (categories.length >= 3) { score += 12; }

    // Calorie balance (20 pts)
    final target = _calTarget;
    if ((totalCal - target).abs() <= 200) { score += 20; }
    else if ((totalCal - target).abs() <= 400) { score += 10; }

    return score.clamp(0, 100);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<AppSettings>(context).locale.languageCode == 'ar';
    final provider = context.watch<NutritionProvider>();

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
          title: Text(isArabic ? 'التغذية الذكية' : 'Smart Nutrition'),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: false,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            tabs: [
              Tab(text: isArabic ? 'الخطة' : 'Plan', icon: const Icon(Icons.restaurant_menu, size: 18)),
              Tab(text: isArabic ? 'الدليل' : 'Guide', icon: const Icon(Icons.menu_book, size: 18)),
              Tab(text: isArabic ? 'التحليل' : 'Analytics', icon: const Icon(Icons.bar_chart, size: 18)),
              Tab(text: isArabic ? 'التذكيرات' : 'Reminders', icon: const Icon(Icons.alarm, size: 18)),
            ],
          ),
        ),
        floatingActionButton: _tabIndex == 2
            ? FloatingActionButton.extended(
                heroTag: 'nutrition_add_fab',
                onPressed: () => _showAddSheet(context, isArabic),
                icon: const Icon(Icons.add),
                label: Text(isArabic ? 'إضافة وجبة' : 'Add Meal'),
              )
            : null,
        body: TabBarView(
          controller: _tabController,
          children: [
            _tab1MealPlan(isArabic: isArabic, provider: provider),
            _tab2FoodsGuide(isArabic: isArabic),
            _tab3Analytics(isArabic: isArabic, provider: provider),
            _tab4Reminders(isArabic: isArabic),
          ],
        ),
      ),
    );
  }

  // ── Tab 1 ──────────────────────────────────────────────────────────────────

  Widget _tab1MealPlan({required bool isArabic, required NutritionProvider provider}) {
    final historyProvider = context.watch<HealthHistoryProvider>();
    final riskAlert = historyProvider.currentAlert;

    return RefreshIndicator(
      onRefresh: provider.loadToday,
      child: AnimatedBuilder(
        animation: _tabController,
        builder: (_, __) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            // Risk Banner
            _buildRiskBanner(riskAlert, isArabic),
            const SizedBox(height: 12),

            // Patient input card
            _buildPatientInputCard(isArabic),
            const SizedBox(height: 12),

            // Generate button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.auto_awesome),
                label: Text(
                  isArabic ? '✨ توليد خطة ذكية' : '✨ Generate Smart Plan',
                  style: const TextStyle(fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: const Color(0xFF4C6FFF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  await _saveProfile();
                  _generatePlan();
                },
              ),
            ),

            if (_planGenerated) ...[
              const SizedBox(height: 16),
              // Nutrition score
              _buildScoreCard(isArabic),
              const SizedBox(height: 16),
              // Meal cards
              ..._plan.asMap().entries.map((e) => _buildMealCard(e.key, e.value, isArabic)),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(
                isArabic ? '📅 عرض الخطة الأسبوعية' : '📅 View Weekly Plan',
                style: const TextStyle(fontSize: 14),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                side: const BorderSide(color: Color(0xFF4C6FFF)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WeeklyPlanScreen(
                    weight: _weight,
                    bloodSugar: _bloodSugar,
                    activity: _activity,
                    goal: _goal,
                    disliked: _disliked,
                    diet: _diet,
                    isArabic: isArabic,
                    isCritical: _isCritical,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskBanner(AlertResult? alert, bool isArabic) {
    if (alert == null || alert.level == AlertLevel.none) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            const Text('✅', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isArabic
                    ? 'وضعك جيد، استمر في نظامك الغذائي الصحي'
                    : 'Good status, keep following your healthy diet',
                style: TextStyle(color: Colors.green.shade700, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    final isCritical = alert.level == AlertLevel.critical;
    final color = isCritical ? Colors.red : Colors.orange;
    final icon = isCritical ? '🚨' : '⚠️';
    final message = isCritical
        ? (isArabic
            ? 'خطر مرتفع: قلل السكريات وزد البروتين لدعم التئام الجروح اليوم'
            : 'High risk: Reduce sugars & increase protein for wound healing today')
        : (isArabic
            ? 'تنبيه: تجنب الأطعمة ذات المؤشر الجلايسيمي العالي اليوم'
            : 'Warning: Avoid high glycemic foods today');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                  color: color.shade700,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientInputCard(bool isArabic) {
    final bloodSugarOptions = isArabic
        ? ['طبيعي', 'ما قبل السكري', 'سكري', 'مرتفع جداً']
        : ['Normal', 'Pre-diabetic', 'Diabetic', 'Very High'];
    const bloodSugarKeys = ['normal', 'pre_diabetic', 'diabetic', 'high'];

    final activityOptions = isArabic
        ? ['خامل', 'خفيف', 'معتدل', 'نشيط']
        : ['Sedentary', 'Light', 'Moderate', 'Active'];
    const activityKeys = ['sedentary', 'light', 'moderate', 'active'];

    final goalOptions = isArabic
        ? ['ضبط السكر', 'فقدان الوزن', 'الحفاظ', 'شفاء الجروح']
        : ['Control Sugar', 'Lose Weight', 'Maintain', 'Wound Healing'];
    const goalKeys = ['control_sugar', 'lose_weight', 'maintain', 'wound_healing'];

    return Card(
      child: Column(
        children: [
          // Section 1: Weight & Blood Sugar
          ExpansionTile(
            initiallyExpanded: true,
            leading: const Icon(Icons.monitor_weight_outlined, color: Color(0xFF4C6FFF)),
            title: Text(
              isArabic ? 'الوزن ومستوى السكر' : 'Weight & Blood Sugar',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(isArabic ? 'الوزن:' : 'Weight:',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        Text(
                          '${_weight.toInt()} ${isArabic ? 'كغ' : 'kg'}',
                          style: const TextStyle(color: Color(0xFF4C6FFF), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Slider(
                      value: _weight,
                      min: 40,
                      max: 150,
                      divisions: 110,
                      activeColor: const Color(0xFF4C6FFF),
                      onChanged: (v) => setState(() => _weight = v),
                    ),
                    const SizedBox(height: 8),
                    Text(isArabic ? 'مستوى السكر:' : 'Blood Sugar:',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: List.generate(
                        bloodSugarKeys.length,
                        (i) => ChoiceChip(
                          label: Text(bloodSugarOptions[i], style: const TextStyle(fontSize: 11)),
                          selected: _bloodSugar == bloodSugarKeys[i],
                          onSelected: (v) {
                            if (v) setState(() => _bloodSugar = bloodSugarKeys[i]);
                          },
                          selectedColor: const Color(0xFF4C6FFF).withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Section 2: Activity & Goal
          ExpansionTile(
            leading: const Icon(Icons.fitness_center, color: Colors.green),
            title: Text(
              isArabic ? 'النشاط والهدف' : 'Activity & Goal',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isArabic ? 'مستوى النشاط:' : 'Activity Level:',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: List.generate(
                        activityKeys.length,
                        (i) => ChoiceChip(
                          label: Text(activityOptions[i], style: const TextStyle(fontSize: 11)),
                          selected: _activity == activityKeys[i],
                          onSelected: (v) {
                            if (v) setState(() => _activity = activityKeys[i]);
                          },
                          selectedColor: Colors.green.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(isArabic ? 'الهدف:' : 'Goal:',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: List.generate(
                        goalKeys.length,
                        (i) => ChoiceChip(
                          label: Text(goalOptions[i], style: const TextStyle(fontSize: 11)),
                          selected: _goal == goalKeys[i],
                          onSelected: (v) {
                            if (v) setState(() => _goal = goalKeys[i]);
                          },
                          selectedColor: Colors.orange.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Section 3: Health Conditions & Diet
          ExpansionTile(
            leading: const Icon(Icons.medical_services_outlined, color: Colors.red),
            title: Text(
              isArabic ? 'الحالات الصحية والنظام' : 'Health & Diet Type',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? 'الحالات الصحية:' : 'Health Conditions:',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (int i = 0; i < 5; i++)
                          FilterChip(
                            label: Text(
                              isArabic
                                  ? ['السكري النوع الثاني', 'مشاكل الكلى', 'أمراض القلب', 'ضغط الدم', 'السمنة'][i]
                                  : ['Type 2 Diabetes', 'Kidney Issues', 'Heart Conditions', 'High Blood Pressure', 'Obesity'][i],
                              style: const TextStyle(fontSize: 11),
                            ),
                            selected: _conditions.contains(
                                ['diabetes', 'kidney', 'heart', 'hypertension', 'obesity'][i]),
                            onSelected: (v) => setState(() {
                              final key = ['diabetes', 'kidney', 'heart', 'hypertension', 'obesity'][i];
                              if (v) { _conditions.add(key); } else { _conditions.remove(key); }
                            }),
                            selectedColor: const Color(0xFF4C6FFF).withValues(alpha: 0.2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isArabic ? 'نوع النظام الغذائي:' : 'Diet Type:',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (int i = 0; i < 4; i++)
                          ChoiceChip(
                            label: Text(
                              isArabic
                                  ? ['متنوع', 'نباتي', 'غني بالبروتين', 'خفيف'][i]
                                  : ['Mixed', 'Vegetarian', 'High Protein', 'Light'][i],
                              style: const TextStyle(fontSize: 11),
                            ),
                            selected: _diet == ['mixed', 'vegetarian', 'highProtein', 'light'][i],
                            onSelected: (v) {
                              if (v) setState(() => _diet = ['mixed', 'vegetarian', 'highProtein', 'light'][i]);
                            },
                            selectedColor: Colors.orange.withValues(alpha: 0.2),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Section 4: Liked / Disliked
          ExpansionTile(
            leading: const Icon(Icons.favorite_outline, color: Colors.pink),
            title: Text(
              isArabic ? 'تفضيلات الطعام' : 'Food Preferences',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.favorite_outline, size: 16, color: Colors.green),
                        label: Text(
                          isArabic ? 'المفضلة (${_liked.length})' : 'Liked (${_liked.length})',
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () => _showFoodPicker(
                          isArabic: isArabic,
                          title: isArabic ? 'الأطعمة المفضلة' : 'Liked Foods',
                          selected: List.from(_liked),
                          onSave: (v) => setState(() => _liked = v),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.not_interested, size: 16, color: Colors.red),
                        label: Text(
                          isArabic ? 'مكروهة (${_disliked.length})' : 'Disliked (${_disliked.length})',
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () => _showFoodPicker(
                          isArabic: isArabic,
                          title: isArabic ? 'الأطعمة غير المرغوبة' : 'Disliked Foods',
                          selected: List.from(_disliked),
                          onSave: (v) => setState(() => _disliked = v),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(bool isArabic) {
    final score = _computeScore();
    Color scoreColor;
    String scoreLabel;
    if (score >= 80) {
      scoreColor = Colors.green;
      scoreLabel = isArabic ? 'ممتاز' : 'Excellent';
    } else if (score >= 60) {
      scoreColor = Colors.orange;
      scoreLabel = isArabic ? 'جيد' : 'Good';
    } else {
      scoreColor = Colors.red;
      scoreLabel = isArabic ? 'يحتاج تحسين' : 'Needs Improvement';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(scoreColor),
                  ),
                  Text('$score',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: scoreColor)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic ? 'تقييم الخطة الغذائية' : 'Meal Plan Score',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: scoreColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(scoreLabel,
                        style: TextStyle(
                            color: scoreColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${isArabic ? 'هدف السعرات' : 'Cal Target'}: ${_calTarget.toInt()} kcal',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealCard(int index, _PlannedMeal meal, bool isArabic) {
    final mealNames = {
      'breakfast': isArabic ? '🌅 الإفطار' : '🌅 Breakfast',
      'snack1': isArabic ? '🍎 وجبة خفيفة' : '🍎 Snack',
      'lunch': isArabic ? '☀️ الغداء' : '☀️ Lunch',
      'snack2': isArabic ? '🍌 وجبة خفيفة' : '🍌 Snack',
      'dinner': isArabic ? '🌙 العشاء' : '🌙 Dinner',
    };
    final gi = meal.maxGi;
    final giC = _giColor(gi);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: giC.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    mealNames[meal.typeKey] ?? meal.typeKey,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                // GI badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: giC.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_giLabel(gi),
                      style: TextStyle(color: giC, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 6),
                // Replace meal button
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _regenerateMeal(index),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.refresh, size: 18, color: Color(0xFF4C6FFF)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Food items
            ...meal.foods.asMap().entries.map((e) {
              final fi = e.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                          color: _giColor(fi.gi), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(isArabic ? fi.nameAr : fi.nameEn,
                          style: const TextStyle(fontSize: 13)),
                    ),
                    if (_isCritical && _healingFoodNames.contains(fi.nameAr))
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
                    Text('${fi.cal.toInt()} kcal',
                        style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => _swapFood(index, e.key),
                      child: const Icon(Icons.swap_horiz, size: 16, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  '${isArabic ? 'إجمالي' : 'Total'}: ${meal.totalCal.toInt()} kcal  ·  Carbs: ${meal.totalCarbs.toStringAsFixed(0)}g',
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
            if (gi > 70)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  isArabic ? '⚠️ تأثير عالٍ على السكر' : '⚠️ High sugar impact',
                  style: const TextStyle(
                      color: Colors.red, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Tab 2 ──────────────────────────────────────────────────────────────────

  Widget _tab2FoodsGuide({required bool isArabic}) {
    final recommended = _allFoods.where((f) => f.gi > 0 && f.gi < 55).toList()
      ..sort((a, b) => a.gi.compareTo(b.gi));

    const avoidFoods = [
      ('السكر الأبيض', 'White Sugar', 100),
      ('الخبز الأبيض', 'White Bread', 75),
      ('البطاطس المقلية', 'Fried Potatoes', 85),
      ('المشروبات الغازية', 'Soft Drinks', 65),
      ('الأرز الأبيض', 'White Rice', 72),
      ('الحلوى', 'Sweets/Candy', 80),
      ('المعجنات', 'Pastries', 70),
      ('العصائر المعلبة', 'Packaged Juice', 75),
    ];

    const healingFoods = [
      ('السلمون', 'Salmon', Icons.water, 'أوميغا 3، مضاد للالتهابات', 'Omega-3, anti-inflammatory'),
      ('البروكلي', 'Broccoli', Icons.eco, 'فيتامين C، يدعم الشفاء', 'Vitamin C, wound healing'),
      ('السبانخ', 'Spinach', Icons.grass, 'الحديد، يدعم التئام الجروح', 'Iron, healing support'),
      ('اللوز', 'Almonds', Icons.grain, 'فيتامين E، الزنك', 'Vitamin E, zinc'),
      ('البيض', 'Eggs', Icons.egg_outlined, 'بروتين، الزنك', 'Protein, zinc'),
      ('الكركم', 'Turmeric', Icons.local_florist, 'مضاد للالتهابات', 'Anti-inflammatory'),
      ('الثوم', 'Garlic', Icons.spa, 'يعزز المناعة', 'Immune boost'),
      ('الأفوكادو', 'Avocado', Icons.spa_outlined, 'دهون صحية، فيتامين E', 'Healthy fats, vitamin E'),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Recommended
        Card(
          child: ExpansionTile(
            initiallyExpanded: true,
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: Text(
              isArabic ? '🟢 الأطعمة الموصى بها' : '🟢 Recommended Foods',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  children: recommended
                      .map((f) => _FoodGuideTile(
                            nameAr: f.nameAr,
                            nameEn: f.nameEn,
                            gi: f.gi,
                            badge: _giLabel(f.gi),
                            badgeColor: Colors.green,
                            isArabic: isArabic,
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 2. Avoid
        Card(
          child: ExpansionTile(
            leading: const Icon(Icons.cancel, color: Colors.red),
            title: Text(
              isArabic ? '🔴 الأطعمة الممنوعة' : '🔴 Foods to Avoid',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  children: avoidFoods
                      .map((r) => _FoodGuideTile(
                            nameAr: r.$1,
                            nameEn: r.$2,
                            gi: r.$3,
                            badge: 'GI: ${r.$3} 🔴',
                            badgeColor: Colors.red,
                            subtitle: isArabic
                                ? 'يرفع السكر بسرعة'
                                : 'Raises blood sugar quickly',
                            isArabic: isArabic,
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 3. Healing
        Card(
          child: ExpansionTile(
            leading: const Icon(Icons.favorite, color: Color(0xFF00B4A6)),
            title: Text(
              isArabic ? '💚 أطعمة الشفاء' : '💚 Healing Foods',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  children: healingFoods
                      .map((h) => ListTile(
                            dense: true,
                            leading: Icon(h.$3, color: const Color(0xFF00897B), size: 22),
                            title: Text(isArabic ? h.$1 : h.$2,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            subtitle: Text(isArabic ? h.$4 : h.$5,
                                style: const TextStyle(fontSize: 11, color: Colors.teal)),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Tab 3 ──────────────────────────────────────────────────────────────────

  Widget _tab3Analytics({required bool isArabic, required NutritionProvider provider}) {
    final s = provider.summary;
    final calTarget = _calTarget;
    final carbTarget = _targetCarbs;

    // Glycemic load
    double gl = 0;
    for (final m in provider.todayMeals) {
      gl += m.carbs * m.glucoseImpact;
    }
    final glColor = gl < 10 ? Colors.green : gl <= 20 ? Colors.orange : Colors.red;
    final glLabel = gl < 10
        ? (isArabic ? 'آمن' : 'Safe')
        : gl <= 20
            ? (isArabic ? 'متوسط' : 'Moderate')
            : (isArabic ? 'مرتفع' : 'High');

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // Today summary
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? '📊 ملخص اليوم' : '📊 Today\'s Summary',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 14),
                _ProgressRow(
                  label: isArabic ? 'السعرات' : 'Calories',
                  value: s.totalCalories,
                  target: calTarget,
                  unit: 'kcal',
                  color: const Color(0xFF4C6FFF),
                ),
                const SizedBox(height: 8),
                _ProgressRow(
                  label: isArabic ? 'الكربوهيدرات' : 'Carbs',
                  value: s.totalCarbs,
                  target: carbTarget,
                  unit: 'g',
                  color: Colors.orange,
                ),
                const SizedBox(height: 8),
                _ProgressRow(
                  label: isArabic ? 'البروتين' : 'Protein',
                  value: s.totalProtein,
                  target: _targetProtein,
                  unit: 'g',
                  color: Colors.green,
                ),
                const SizedBox(height: 8),
                _ProgressRow(
                  label: isArabic ? 'الدهون' : 'Fat',
                  value: s.totalFat,
                  target: _targetFat,
                  unit: 'g',
                  color: Colors.purple,
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    Text(
                      isArabic ? 'الحمل الجلايسيمي:' : 'Glycemic Load:',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: glColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: glColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        '${gl.toStringAsFixed(1)}  $glLabel',
                        style: TextStyle(
                            color: glColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // GL Explanation
        Card(
          color: const Color(0xFF4C6FFF).withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'مؤشر الحمل الجلايسيمي' : 'Glycemic Load (GL)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF4C6FFF)),
                ),
                const SizedBox(height: 6),
                Text(
                  isArabic
                      ? 'GL = الكربوهيدرات × المؤشر الجلايسيمي ÷ 100\nالحد الآمن اليومي لمرضى السكري: أقل من 100'
                      : 'GL = Carbs × Glycemic Index ÷ 100\nSafe daily GL for diabetics: < 100',
                  style: const TextStyle(fontSize: 12, height: 1.5, color: Colors.black87),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Meals log
        if (provider.todayMeals.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Text(
                isArabic
                    ? 'لم تسجل أي وجبات اليوم\nاضغط + لإضافة وجبة'
                    : 'No meals logged today\nTap + to add a meal',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, height: 1.6),
              ),
            ),
          )
        else ...[
          Text(
            isArabic ? 'سجل الوجبات:' : "Today's Meals:",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          ...provider.todayMeals.map(
            (meal) => _LogTile(
              meal: meal,
              isArabic: isArabic,
              onDelete: () => provider.deleteMeal(meal.id),
            ),
          ),
        ],
      ],
    );
  }

  // ── Tab 4 ──────────────────────────────────────────────────────────────────

  Widget _tab4Reminders({required bool isArabic}) {
    final reminders = [
      (isArabic ? '🌅 تذكير الإفطار' : '🌅 Breakfast Reminder', '7:00 AM', Icons.wb_sunny_outlined),
      (isArabic ? '☀️ تذكير الغداء' : '☀️ Lunch Reminder', '1:00 PM', Icons.lunch_dining),
      (isArabic ? '🌙 تذكير العشاء' : '🌙 Dinner Reminder', '7:00 PM', Icons.nightlight_round),
      (isArabic ? '💧 تذكير الماء' : '💧 Water Reminder', isArabic ? 'كل ساعتين' : 'Every 2 hrs', Icons.water_drop_outlined),
      (isArabic ? '💊 تذكير الدواء' : '💊 Medication Reminder', '9:00 AM', Icons.medication_outlined),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF4C6FFF).withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            isArabic
                ? '⏰ فعّل التذكيرات لضبط مواعيد وجباتك وشرب الماء وتناول دوائك'
                : '⏰ Enable reminders to stay on track with meals, water, and medication',
            style: const TextStyle(fontSize: 13, height: 1.4),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(reminders.length, (i) {
          final r = reminders[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF4C6FFF).withValues(alpha: 0.12),
                child: Icon(r.$3, color: const Color(0xFF4C6FFF), size: 22),
              ),
              title: Text(r.$1,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: Text(r.$2,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              trailing: Switch(
                value: _remindersOn[i] ?? false,
                activeThumbColor: const Color(0xFF4C6FFF),
                onChanged: (v) => _toggleReminder(i, v, isArabic),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── Food picker dialog ─────────────────────────────────────────────────────

  void _showFoodPicker({
    required bool isArabic,
    required String title,
    required List<String> selected,
    required ValueChanged<List<String>> onSave,
  }) {
    showDialog(
      context: context,
      builder: (_) => _FoodPickerDialog(
        title: title,
        isArabic: isArabic,
        initialSelected: selected,
        onSave: onSave,
      ),
    );
  }

  // ── Add meal sheet ─────────────────────────────────────────────────────────

  void _showAddSheet(BuildContext context, bool isArabic) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<NutritionProvider>(),
        child: _AddMealSheet(isArabic: isArabic),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Food guide tile
// ─────────────────────────────────────────────────────────────────────────────

class _FoodGuideTile extends StatelessWidget {
  final String nameAr;
  final String nameEn;
  final int gi;
  final String badge;
  final Color badgeColor;
  final String? subtitle;
  final bool isArabic;

  const _FoodGuideTile({
    required this.nameAr,
    required this.nameEn,
    required this.gi,
    required this.badge,
    required this.badgeColor,
    required this.isArabic,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isArabic ? nameAr : nameEn,
                      style: const TextStyle(fontSize: 13)),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: TextStyle(
                            fontSize: 11, color: badgeColor, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(badge,
                  style: TextStyle(
                      color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Progress row (analytics tab)
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressRow extends StatelessWidget {
  final String label;
  final double value;
  final double target;
  final String unit;
  final Color color;

  const _ProgressRow({
    required this.label,
    required this.value,
    required this.target,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = (value / target).clamp(0.0, 1.0);
    final over = value > target;
    final c = over ? Colors.red : color;
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(c),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${value.toStringAsFixed(0)}/${target.toInt()}$unit',
          style: TextStyle(fontSize: 10, color: c, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Log tile (analytics tab)
// ─────────────────────────────────────────────────────────────────────────────

class _LogTile extends StatelessWidget {
  final MealEntry meal;
  final bool isArabic;
  final VoidCallback onDelete;

  const _LogTile({required this.meal, required this.isArabic, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm').format(meal.timestamp);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF4C6FFF).withValues(alpha: 0.1),
          child: const Icon(Icons.restaurant, color: Color(0xFF4C6FFF), size: 20),
        ),
        title: Text(meal.mealName,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        subtitle: Text(
          isArabic
              ? '${meal.calories.toInt()} ك.س · كارب: ${meal.carbs.toStringAsFixed(0)}غ'
              : '${meal.calories.toInt()} kcal · Carbs: ${meal.carbs.toStringAsFixed(0)}g',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Food picker dialog
// ─────────────────────────────────────────────────────────────────────────────

class _FoodPickerDialog extends StatefulWidget {
  final String title;
  final bool isArabic;
  final List<String> initialSelected;
  final ValueChanged<List<String>> onSave;

  const _FoodPickerDialog({
    required this.title,
    required this.isArabic,
    required this.initialSelected,
    required this.onSave,
  });

  @override
  State<_FoodPickerDialog> createState() => _FoodPickerDialogState();
}

class _FoodPickerDialogState extends State<_FoodPickerDialog> {
  late List<String> _selected;
  String _search = '';
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.initialSelected);
    _ctrl.addListener(
        () => setState(() => _search = _ctrl.text.trim().toLowerCase()));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<_FoodData> get _filtered => _search.isEmpty
      ? _allFoods
      : _allFoods
          .where((f) =>
              f.nameAr.contains(_search) ||
              f.nameEn.toLowerCase().contains(_search))
          .toList();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: AlertDialog(
        title: Text(widget.title),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              TextField(
                controller: _ctrl,
                decoration: InputDecoration(
                  hintText: widget.isArabic ? 'بحث...' : 'Search...',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) {
                    final f = _filtered[i];
                    final sel = _selected.contains(f.nameAr);
                    return CheckboxListTile(
                      dense: true,
                      title: Text(f.nameAr, style: const TextStyle(fontSize: 13)),
                      subtitle: Text(f.nameEn, style: const TextStyle(fontSize: 11)),
                      value: sel,
                      onChanged: (v) => setState(() {
                        if (v == true) {
                          _selected.add(f.nameAr);
                        } else {
                          _selected.remove(f.nameAr);
                        }
                      }),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(widget.isArabic ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              widget.onSave(_selected);
              Navigator.pop(context);
            },
            child: Text(widget.isArabic ? 'حفظ' : 'Save'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add meal bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _AddMealSheet extends StatefulWidget {
  final bool isArabic;
  const _AddMealSheet({required this.isArabic});

  @override
  State<_AddMealSheet> createState() => _AddMealSheetState();
}

class _AddMealSheetState extends State<_AddMealSheet> {
  String _search = '';
  final _searchCtrl = TextEditingController();
  _FoodData? _selected;
  double _qty = 1;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(
        () => setState(() => _search = _searchCtrl.text.trim().toLowerCase()));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_FoodData> get _filtered => _search.isEmpty
      ? _allFoods
      : _allFoods
          .where((f) =>
              f.nameAr.contains(_search) ||
              f.nameEn.toLowerCase().contains(_search))
          .toList();

  Future<void> _add() async {
    if (_selected == null) return;
    final f = _selected!;
    final meal = MealEntry(
      mealName: widget.isArabic ? f.nameAr : f.nameEn,
      calories: f.cal * _qty,
      carbs: f.carbs * _qty,
      protein: f.protein * _qty,
      fat: f.fat * _qty,
      fiber: 0,
      glucoseImpact: f.gi / 10.0,
    );
    await context.read<NutritionProvider>().logMeal(meal);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = widget.isArabic;
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isArabic ? '+ إضافة وجبة' : '+ Add Meal',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                labelText: isArabic ? 'بحث عن طعام...' : 'Search food...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 240,
              child: ListView.builder(
                itemCount: _filtered.length,
                itemBuilder: (_, i) {
                  final f = _filtered[i];
                  final isSel = _selected?.nameAr == f.nameAr;
                  final giC = _giColor(f.gi);
                  return ListTile(
                    dense: true,
                    selected: isSel,
                    selectedTileColor: const Color(0xFF4C6FFF).withValues(alpha: 0.08),
                    title: Text(isArabic ? f.nameAr : f.nameEn,
                        style: const TextStyle(fontSize: 13)),
                    subtitle: Text(
                      isArabic
                          ? '${f.cal.toInt()} ك.س · كارب: ${f.carbs.toStringAsFixed(0)}غ'
                          : '${f.cal.toInt()} kcal · Carbs: ${f.carbs.toStringAsFixed(0)}g',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: giC.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(f.gi == 0 ? 'GI: -' : 'GI: ${f.gi}',
                          style: TextStyle(
                              color: giC, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    onTap: () => setState(() => _selected = f),
                  );
                },
              ),
            ),
            if (_selected != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(isArabic ? 'الكمية:' : 'Qty:',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () {
                      if (_qty > 0.5) setState(() => _qty -= 0.5);
                    },
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text(
                    _qty % 1 == 0 ? _qty.toInt().toString() : _qty.toStringAsFixed(1),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _qty += 0.5),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                  const Spacer(),
                  Text(
                    '${(_selected!.cal * _qty).toInt()} kcal',
                    style: const TextStyle(
                        color: Color(0xFF4C6FFF), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _add,
                  child: Text(isArabic ? 'إضافة للسجل' : 'Add to Log'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
