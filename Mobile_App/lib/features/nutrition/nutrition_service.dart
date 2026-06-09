import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

// ── User Food Preferences ────────────────────────────────────────────────────

class UserFoodPreferences {
  final List<String> likedFoods;
  final List<String> dislikedFoods;
  final String dietType; // 'mixed', 'vegetarian', 'highProtein', 'light'
  final bool hasKidneyIssues;
  final bool hasHeartIssues;

  const UserFoodPreferences({
    this.likedFoods = const [],
    this.dislikedFoods = const [],
    this.dietType = 'mixed',
    this.hasKidneyIssues = false,
    this.hasHeartIssues = false,
  });

  Map<String, dynamic> toJson() => {
        'likedFoods': likedFoods,
        'dislikedFoods': dislikedFoods,
        'dietType': dietType,
        'hasKidneyIssues': hasKidneyIssues,
        'hasHeartIssues': hasHeartIssues,
      };

  factory UserFoodPreferences.fromJson(Map<String, dynamic> json) =>
      UserFoodPreferences(
        likedFoods: (json['likedFoods'] as List?)?.cast<String>() ?? [],
        dislikedFoods: (json['dislikedFoods'] as List?)?.cast<String>() ?? [],
        dietType: json['dietType'] as String? ?? 'mixed',
        hasKidneyIssues: json['hasKidneyIssues'] as bool? ?? false,
        hasHeartIssues: json['hasHeartIssues'] as bool? ?? false,
      );

  UserFoodPreferences copyWith({
    List<String>? likedFoods,
    List<String>? dislikedFoods,
    String? dietType,
    bool? hasKidneyIssues,
    bool? hasHeartIssues,
  }) =>
      UserFoodPreferences(
        likedFoods: likedFoods ?? this.likedFoods,
        dislikedFoods: dislikedFoods ?? this.dislikedFoods,
        dietType: dietType ?? this.dietType,
        hasKidneyIssues: hasKidneyIssues ?? this.hasKidneyIssues,
        hasHeartIssues: hasHeartIssues ?? this.hasHeartIssues,
      );
}

// ── Food item model with GI support ──────────────────────────────────────────

class FoodItem {
  final String nameAr;
  final String nameEn;
  final double calories;
  final double carbs;
  final double protein;
  final double fat;
  final double sugar;
  final int glycemicIndex;
  final String category; // 'protein', 'carb', 'vegetable', 'fruit', 'dairy', 'fat', 'drink'
  final bool suitableForDiabetes;
  final bool suitableForKidney;
  final bool suitableForHeart;

  const FoodItem({
    required this.nameAr,
    required this.nameEn,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.sugar,
    required this.glycemicIndex,
    this.category = 'other',
    this.suitableForDiabetes = true,
    this.suitableForKidney = true,
    this.suitableForHeart = true,
  });

  double get glucoseImpact =>
      glycemicIndex == 0 ? 0 : glycemicIndex / 10.0;

  NutritionValues toNutritionValues() => NutritionValues(
        calories: calories,
        carbs: carbs,
        protein: protein,
        fat: fat,
        fiber: 0,
        glucoseImpact: glucoseImpact,
      );
}

// ── Legacy model kept for backward compatibility ──────────────────────────────

class NutritionValues {
  final double calories;
  final double carbs;
  final double protein;
  final double fat;
  final double fiber;
  final double glucoseImpact;

  const NutritionValues({
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.fiber,
    required this.glucoseImpact,
  });
}

class MealEntry {
  final String id;
  final String mealName;
  final double calories;
  final double carbs;
  final double protein;
  final double fat;
  final double fiber;
  final double glucoseImpact;
  final DateTime timestamp;
  final String? notes;

  MealEntry({
    String? id,
    required this.mealName,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.fiber,
    required this.glucoseImpact,
    DateTime? timestamp,
    this.notes,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'meal_name': mealName,
        'calories': calories,
        'carbs': carbs,
        'protein': protein,
        'fat': fat,
        'fiber': fiber,
        'glucose_impact': glucoseImpact,
        'timestamp': timestamp.toIso8601String(),
        'notes': notes,
      };

  factory MealEntry.fromMap(Map<String, dynamic> map) => MealEntry(
        id: map['id'] as String,
        mealName: map['meal_name'] as String,
        calories: (map['calories'] as num).toDouble(),
        carbs: (map['carbs'] as num).toDouble(),
        protein: (map['protein'] as num).toDouble(),
        fat: (map['fat'] as num).toDouble(),
        fiber: (map['fiber'] as num).toDouble(),
        glucoseImpact: (map['glucose_impact'] as num).toDouble(),
        timestamp: DateTime.parse(map['timestamp'] as String),
        notes: map['notes'] as String?,
      );
}

class DailySummary {
  final double totalCalories;
  final double totalCarbs;
  final double totalProtein;
  final double totalFat;
  final double totalFiber;
  final double avgGlucoseImpact;
  final int mealCount;
  final List<MealEntry> meals;

  const DailySummary({
    required this.totalCalories,
    required this.totalCarbs,
    required this.totalProtein,
    required this.totalFat,
    required this.totalFiber,
    required this.avgGlucoseImpact,
    required this.mealCount,
    required this.meals,
  });
}

// ── Meal plan types ───────────────────────────────────────────────────────────

class PlannedMeal {
  final String mealType;
  final List<FoodItem> foods;
  double get totalCarbs => foods.fold(0, (s, f) => s + f.carbs);
  double get totalCalories => foods.fold(0, (s, f) => s + f.calories);

  const PlannedMeal({required this.mealType, required this.foods});
}

class DailyMealPlan {
  final List<PlannedMeal> meals;
  double get totalCalories => meals.fold(0, (s, m) => s + m.totalCalories);
  double get totalCarbs => meals.fold(0, (s, m) => s + m.totalCarbs);

  const DailyMealPlan({required this.meals});
}

// ── Main service ──────────────────────────────────────────────────────────────

class NutritionService {
  // 50+ food items with GI values and categories
  static const _foodItems = <FoodItem>[
    // ── Proteins ─────────────────────────────────────────────────────────────
    FoodItem(
      nameAr: 'صدر دجاج مشوي (100غ)',
      nameEn: 'Grilled Chicken',
      calories: 165, carbs: 0, protein: 31, fat: 3.6, sugar: 0,
      glycemicIndex: 0, category: 'protein',
      suitableForDiabetes: true, suitableForKidney: true, suitableForHeart: true,
    ),
    FoodItem(
      nameAr: 'سمك مشوي (100غ)',
      nameEn: 'Grilled Fish',
      calories: 136, carbs: 0, protein: 27, fat: 3, sugar: 0,
      glycemicIndex: 0, category: 'protein',
      suitableForDiabetes: true, suitableForKidney: true, suitableForHeart: true,
    ),
    FoodItem(
      nameAr: 'تونا معلبة (100غ)',
      nameEn: 'Canned Tuna',
      calories: 116, carbs: 0, protein: 26, fat: 0.5, sugar: 0,
      glycemicIndex: 0, category: 'protein',
      suitableForDiabetes: true, suitableForKidney: true, suitableForHeart: true,
    ),
    FoodItem(
      nameAr: 'بيضة مسلوقة',
      nameEn: 'Boiled Egg',
      calories: 78, carbs: 0.6, protein: 6.3, fat: 5.3, sugar: 0.6,
      glycemicIndex: 0, category: 'protein',
      suitableForDiabetes: true, suitableForKidney: true, suitableForHeart: true,
    ),
    FoodItem(
      nameAr: 'لحم بقري قليل الدهن (100غ)',
      nameEn: 'Lean Beef',
      calories: 217, carbs: 0, protein: 26, fat: 12, sugar: 0,
      glycemicIndex: 0, category: 'protein',
      suitableForDiabetes: true, suitableForKidney: true, suitableForHeart: false,
    ),
    FoodItem(
      nameAr: 'جمبري مطبوخ (100غ)',
      nameEn: 'Cooked Shrimp',
      calories: 99, carbs: 0, protein: 24, fat: 0.3, sugar: 0,
      glycemicIndex: 0, category: 'protein',
      suitableForDiabetes: true, suitableForKidney: true, suitableForHeart: true,
    ),

    // ── Carbs ─────────────────────────────────────────────────────────────────
    FoodItem(
      nameAr: 'أرز بني مطبوخ (100غ)',
      nameEn: 'Cooked Brown Rice',
      calories: 112, carbs: 23, protein: 2.6, fat: 0.9, sugar: 0,
      glycemicIndex: 50, category: 'carb',
      suitableForDiabetes: true, suitableForKidney: true, suitableForHeart: true,
    ),
    FoodItem(
      nameAr: 'أرز أبيض مطبوخ (100غ)',
      nameEn: 'Cooked White Rice',
      calories: 130, carbs: 28, protein: 2.7, fat: 0.3, sugar: 0,
      glycemicIndex: 72, category: 'carb',
      suitableForDiabetes: false, suitableForKidney: true, suitableForHeart: true,
    ),
    FoodItem(
      nameAr: 'شوفان (50غ جاف)',
      nameEn: 'Oats',
      calories: 189, carbs: 32, protein: 6.5, fat: 3.5, sugar: 1,
      glycemicIndex: 55, category: 'carb',
      suitableForDiabetes: true, suitableForKidney: true, suitableForHeart: true,
    ),
    FoodItem(
      nameAr: 'خبز قمح كامل',
      nameEn: 'Whole Wheat Bread',
      calories: 247, carbs: 43, protein: 13, fat: 4.2, sugar: 6,
      glycemicIndex: 68, category: 'carb',
      suitableForDiabetes: true, suitableForKidney: true, suitableForHeart: true,
    ),
    FoodItem(
      nameAr: 'خبز أبيض',
      nameEn: 'White Bread',
      calories: 265, carbs: 49, protein: 9, fat: 3.2, sugar: 5,
      glycemicIndex: 75, category: 'carb',
      suitableForDiabetes: false, suitableForKidney: true, suitableForHeart: true,
    ),
    FoodItem(
      nameAr: 'معكرونة مسلوقة (100غ)',
      nameEn: 'Cooked Pasta',
      calories: 158, carbs: 31, protein: 5.8, fat: 0.9, sugar: 0.6,
      glycemicIndex: 55, category: 'carb',
      suitableForDiabetes: true, suitableForKidney: true, suitableForHeart: true,
    ),
    FoodItem(
      nameAr: 'بطاطا حلوة (100غ)',
      nameEn: 'Sweet Potato',
      calories: 86, carbs: 20, protein: 1.6, fat: 0.1, sugar: 4.2,
      glycemicIndex: 44, category: 'carb',
      suitableForDiabetes: true, suitableForKidney: true, suitableForHeart: true,
    ),
    FoodItem(
      nameAr: 'بطاطا مسلوقة (100غ)',
      nameEn: 'Boiled Potato',
      calories: 77, carbs: 17, protein: 2, fat: 0.1, sugar: 0.8,
      glycemicIndex: 78, category: 'carb',
      suitableForDiabetes: false, suitableForKidney: true, suitableForHeart: true,
    ),
    FoodItem(
      nameAr: 'عدس مطبوخ (100غ)',
      nameEn: 'Cooked Lentils',
      calories: 116, carbs: 20, protein: 9, fat: 0.4, sugar: 1.8,
      glycemicIndex: 32, category: 'carb',
      suitableForDiabetes: true, suitableForKidney: true, suitableForHeart: true,
    ),
    FoodItem(
      nameAr: 'فاصوليا مطبوخة (100غ)',
      nameEn: 'Cooked Beans',
      calories: 127, carbs: 23, protein: 8.7, fat: 0.5, sugar: 0.4,
      glycemicIndex: 24, category: 'carb',
      suitableForDiabetes: true, suitableForKidney: true, suitableForHeart: true,
    ),
    FoodItem(
      nameAr: 'حمص مطبوخ (100غ)',
      nameEn: 'Cooked Chickpeas',
      calories: 164, carbs: 27, protein: 8.9, fat: 2.6, sugar: 4.8,
      glycemicIndex: 28, category: 'carb',
      suitableForDiabetes: true, suitableForKidney: true, suitableForHeart: true,
    ),

    // ── Vegetables ───────────────────────────────────────────────────────────
    FoodItem(
      nameAr: 'سلطة خضراء',
      nameEn: 'Green Salad',
      calories: 20, carbs: 3.5, protein: 1.5, fat: 0.2, sugar: 2,
      glycemicIndex: 10, category: 'vegetable',
      suitableForDiabetes: true, suitableForKidney: true, suitableForHeart: true,
    ),
    FoodItem(
      nameAr: 'طماطم (100غ)',
      nameEn: 'Tomato',
      calories: 18, carbs: 3.9, protein: 0.9, fat: 0.2, sugar: 2.6,
      glycemicIndex: 15, category: 'vegetable',
      suitableForDiabetes: true, suitableForKidney: true, suitableForHeart: true,
    ),
    FoodItem(
      nameAr: 'خيار (100غ)',
      nameEn: 'Cucumber',
      calories: 16, carbs: 3.6, protein: 0.7, fat: 0.1, sugar: 1.7,
      glycemicIndex: 15, category: 'vegetable',
      suitableForDiabetes: true, suitableForKidney: true, suitableForHeart: true,
    ),
    FoodItem(
      nameAr: 'بروكلي (100غ)',
      nameEn: 'Broccoli',
      calories: 34, carbs: 7, protein: 2.8, fat: 0.4, sugar: 1.7,
      glycemicIndex: 10, category: 'vegetable',
      suitableForDiabetes: true, suitableForKidney: true, suitableForHeart: true,
    ),
    FoodItem(
      nameAr: 'سبانخ (100غ)',
      nameEn: 'Spinach',
      calories: 23, carbs: 3.6, protein: 2.9, fat: 0.4, sugar: 0.4,
      glycemicIndex: 15, category: 'vegetable',
      suitableForDiabetes: true, suitableForKidney: false, suitableForHeart: true,
    ),
    FoodItem(
      nameAr: 'جزر (100غ)',
      nameEn: 'Carrot',
      calories: 41, carbs: 10, protein: 0.9, fat: 0.2, sugar: 4.7,
      glycemicIndex: 35, category: 'vegetable',
      suitableForDiabetes: true, suitableForKidney: true, suitableForHeart: true,
    ),
    FoodItem(
      nameAr: 'كوسا (100غ)',
      nameEn: 'Zucchini',
      calories: 17, carbs: 3.1, protein: 1.2, fat: 0.3, sugar: 2.5,
      glycemicIndex: 15, category: 'vegetable',
      suitableForDiabetes: true, suitableForKidney: true, suitableForHeart: true,
    ),
    FoodItem(
      nameAr: 'بصل (100غ)',
      nameEn: 'Onion',
      calories: 40, carbs: 9, protein: 1.1, fat: 0.1, sugar: 4.2,
      glycemicIndex: 10, category: 'vegetable',
      suitableForDiabetes: true, suitableForKidney: true, suitableForHeart: true,
    ),
    FoodItem(
      nameAr: 'فلفل أحمر (100غ)',
      nameEn: 'Red Pepper',
      calories: 31, carbs: 6, protein: 1, fat: 0.3, sugar: 4.2,
      glycemicIndex: 15, category: 'vegetable',
      suitableForDiabetes: true, suitableForKidney: true, suitableForHeart: true,
    ),
    FoodItem(
      nameAr: 'ثوم (فص)',
      nameEn: 'Garlic',
      calories: 4, carbs: 1, protein: 0.2, fat: 0, sugar: 0,
      glycemicIndex: 10, category: 'vegetable',
      suitableForDiabetes: true, suitableForKidney: true, suitableForHeart: true,
    ),

    // ── Fruits ───────────────────────────────────────────────────────────────
    FoodItem(
      nameAr: 'تفاحة متوسطة',
      nameEn: 'Apple',
      calories: 95, carbs: 25, protein: 0.5, fat: 0.3, sugar: 19,
      glycemicIndex: 36, category: 'fruit',
      suitableForDiabetes: true, suitableForKidney: true, suitableForHeart: true,
    ),
    FoodItem(
      nameAr: 'برتقال',
      nameEn: 'Orange',
      calories: 62, carbs: 15, protein: 1.2, fat: 0.2, sugar: 12,
      glycemicIndex: 43, category: 'fruit',
      suitableForDiabetes: true, suitableForKidney: true, suitableForHeart: true,
    ),
    FoodItem(
      nameAr: 'موز متوسط',
      nameEn: 'Banana',
      calories: 105, carbs: 27, protein: 1.3, fat: 0.4, sugar: 14,
      glycemicIndex: 51, category: 'fruit',
      suitableForDiabetes: true, suitableForKidney: true, suitableForHeart: true,
    ),
    FoodItem(
      nameAr: 'بطيخ (200غ)',
      nameEn: 'Watermelon',
      calories: 60, carbs: 15.2, protein: 1.2, fat: 0.4, sugar: 12.4,
      glycemicIndex: 72, category: 'fruit',
      suitableForDiabetes: false, suitableForKidney: true, suitableForHeart: true,
    ),
    FoodItem(
      nameAr: 'عنب (100غ)',
      nameEn: 'Grapes',
      calories: 69, carbs: 18, protein: 0.7, fat: 0.2, sugar: 15.5,
      glycemicIndex: 59, category: 'fruit',
      suitableForDiabetes: true, suitableForKidney: true, suitableForHeart: true,
    ),
    FoodItem(
      nameAr: 'مانجو (100غ)',
      nameEn: 'Mango',
      calories: 60, carbs: 15, protein: 0.8, fat: 0.4, sugar: 13.7,
      glycemicIndex: 56, category: 'fruit',
      suitableForDiabetes: true, suitableForKidney: true, suitableForHeart: true,
    ),
    FoodItem(
      nameAr: 'فراولة (100غ)',
      nameEn: 'Strawberry',
      calories: 32, carbs: 7.7, protein: 0.7, fat: 0.3, sugar: 4.9,
      glycemicIndex: 40, category: 'fruit',
      suitableForDiabetes: true, suitableForKidney: true, suitableForHeart: true,
    ),
    FoodItem(
      nameAr: 'تمر (3 حبات)',
      nameEn: 'Dates',
      calories: 69, carbs: 18.6, protein: 0.6, fat: 0, sugar: 16.8,
      glycemicIndex: 42, category: 'fruit',
      suitableForDiabetes: true, suitableForKidney: true, suitableForHeart: true,
    ),
    FoodItem(
      nameAr: 'تين (حبتان)',
      nameEn: 'Figs',
      calories: 74, carbs: 19, protein: 0.7, fat: 0.3, sugar: 16,
      glycemicIndex: 61, category: 'fruit',
      suitableForDiabetes: true, suitableForKidney: true, suitableForHeart: true,
    ),

    // ── Dairy ─────────────────────────────────────────────────────────────────
    FoodItem(
      nameAr: 'حليب قليل الدسم (200مل)',
      nameEn: 'Low-Fat Milk',
      calories: 92, carbs: 9.6, protein: 6.4, fat: 2.5, sugar: 10,
      glycemicIndex: 32, category: 'dairy',
      suitableForDiabetes: true, suitableForKidney: true, suitableForHeart: true,
    ),
    FoodItem(
      nameAr: 'حليب كامل (200مل)',
      nameEn: 'Whole Milk',
      calories: 122, carbs: 9.6, protein: 6.4, fat: 6.6, sugar: 10,
      glycemicIndex: 39, category: 'dairy',
      suitableForDiabetes: true, suitableForKidney: true, suitableForHeart: true,
    ),
    FoodItem(
      nameAr: 'لبن زبادي قليل الدسم (200مل)',
      nameEn: 'Low-Fat Yogurt',
      calories: 100, carbs: 7.7, protein: 8.5, fat: 3.8, sugar: 7.7,
      glycemicIndex: 36, category: 'dairy',
      suitableForDiabetes: true, suitableForKidney: true, suitableForHeart: true,
    ),
    FoodItem(
      nameAr: 'جبن أبيض (30غ)',
      nameEn: 'White Cheese',
      calories: 90, carbs: 0.4, protein: 6, fat: 7, sugar: 0.2,
      glycemicIndex: 0, category: 'dairy',
      suitableForDiabetes: true, suitableForKidney: true, suitableForHeart: true,
    ),
    FoodItem(
      nameAr: 'لبنة (50غ)',
      nameEn: 'Labneh',
      calories: 78, carbs: 2.5, protein: 5, fat: 5.5, sugar: 2,
      glycemicIndex: 0, category: 'dairy',
      suitableForDiabetes: true, suitableForKidney: true, suitableForHeart: true,
    ),
    FoodItem(
      nameAr: 'جبن (30غ)',
      nameEn: 'Cheese',
      calories: 120, carbs: 0.4, protein: 7.5, fat: 9.9, sugar: 0.2,
      glycemicIndex: 0, category: 'dairy',
      suitableForDiabetes: true, suitableForKidney: true, suitableForHeart: true,
    ),

    // ── Fats ─────────────────────────────────────────────────────────────────
    FoodItem(
      nameAr: 'زيت زيتون (ملعقة)',
      nameEn: 'Olive Oil',
      calories: 119, carbs: 0, protein: 0, fat: 13.5, sugar: 0,
      glycemicIndex: 0, category: 'fat',
      suitableForDiabetes: true, suitableForKidney: true, suitableForHeart: true,
    ),
    FoodItem(
      nameAr: 'لوز (30غ)',
      nameEn: 'Almonds',
      calories: 174, carbs: 6, protein: 6, fat: 15, sugar: 1.2,
      glycemicIndex: 0, category: 'fat',
      suitableForDiabetes: true, suitableForKidney: true, suitableForHeart: true,
    ),
    FoodItem(
      nameAr: 'جوز (30غ)',
      nameEn: 'Walnuts',
      calories: 196, carbs: 4, protein: 4.6, fat: 19.6, sugar: 0.7,
      glycemicIndex: 0, category: 'fat',
      suitableForDiabetes: true, suitableForKidney: true, suitableForHeart: true,
    ),
    FoodItem(
      nameAr: 'أفوكادو (نصف)',
      nameEn: 'Avocado',
      calories: 160, carbs: 8.5, protein: 2, fat: 14.7, sugar: 0.7,
      glycemicIndex: 10, category: 'fat',
      suitableForDiabetes: true, suitableForKidney: true, suitableForHeart: true,
    ),
    FoodItem(
      nameAr: 'مكسرات مشكلة (30غ)',
      nameEn: 'Mixed Nuts',
      calories: 182, carbs: 6.3, protein: 6, fat: 16.2, sugar: 1.2,
      glycemicIndex: 15, category: 'fat',
      suitableForDiabetes: true, suitableForKidney: true, suitableForHeart: true,
    ),

    // ── Drinks ───────────────────────────────────────────────────────────────
    FoodItem(
      nameAr: 'ماء (كوب)',
      nameEn: 'Water',
      calories: 0, carbs: 0, protein: 0, fat: 0, sugar: 0,
      glycemicIndex: 0, category: 'drink',
      suitableForDiabetes: true, suitableForKidney: true, suitableForHeart: true,
    ),
    FoodItem(
      nameAr: 'شاي أخضر',
      nameEn: 'Green Tea',
      calories: 0, carbs: 0, protein: 0, fat: 0, sugar: 0,
      glycemicIndex: 0, category: 'drink',
      suitableForDiabetes: true, suitableForKidney: true, suitableForHeart: true,
    ),
    FoodItem(
      nameAr: 'شاي (كوب)',
      nameEn: 'Tea',
      calories: 1, carbs: 0.2, protein: 0, fat: 0, sugar: 0,
      glycemicIndex: 0, category: 'drink',
      suitableForDiabetes: true, suitableForKidney: true, suitableForHeart: true,
    ),
    FoodItem(
      nameAr: 'قهوة بدون سكر',
      nameEn: 'Black Coffee',
      calories: 2, carbs: 0, protein: 0.3, fat: 0, sugar: 0,
      glycemicIndex: 0, category: 'drink',
      suitableForDiabetes: true, suitableForKidney: true, suitableForHeart: true,
    ),
    FoodItem(
      nameAr: 'عصير برتقال طازج (200مل)',
      nameEn: 'Fresh Orange Juice',
      calories: 90, carbs: 20.8, protein: 1.4, fat: 0.4, sugar: 16.8,
      glycemicIndex: 50, category: 'drink',
      suitableForDiabetes: true, suitableForKidney: true, suitableForHeart: true,
    ),
  ];

  // ── Accessors ─────────────────────────────────────────────────────────────

  static List<FoodItem> get availableFoodItems => _foodItems;

  static List<String> get availableFoods =>
      _foodItems.map((f) => f.nameAr).toList();

  static FoodItem? foodItemForAr(String nameAr) {
    try {
      return _foodItems.firstWhere((f) => f.nameAr == nameAr);
    } catch (_) {
      return null;
    }
  }

  static NutritionValues? nutritionFor(String name) =>
      foodItemForAr(name)?.toNutritionValues();

  // ── GI helpers ────────────────────────────────────────────────────────────

  static Color giColor(int gi) {
    if (gi > 70) return const Color(0xFFD32F2F);
    if (gi >= 55) return const Color(0xFFF57F17);
    return const Color(0xFF388E3C);
  }

  static String giLabel(int gi) {
    if (gi > 70) return '⚠️ تأثير عالٍ على السكر';
    if (gi >= 55) return 'تأثير متوسط';
    if (gi == 0) return 'لا يؤثر على السكر';
    return 'آمن لمرضى السكري';
  }

  static String giCategory(int gi) {
    if (gi > 70) return 'مرتفع';
    if (gi >= 55) return 'متوسط';
    return 'منخفض';
  }

  // ── Impact helpers ────────────────────────────────────────────────────────

  static String impactLabel(double impact, {bool isArabic = true}) {
    if (isArabic) {
      if (impact >= 7) return 'مرتفع جداً';
      if (impact >= 5) return 'مرتفع';
      if (impact >= 3) return 'متوسط';
      return 'منخفض';
    } else {
      if (impact >= 7) return 'Very High';
      if (impact >= 5) return 'High';
      if (impact >= 3) return 'Moderate';
      return 'Low';
    }
  }

  static String impactAdvice(double avgImpact, {bool isArabic = true}) {
    if (isArabic) {
      if (avgImpact >= 7) {
        return 'التأثير على السكر مرتفع جداً. قلل الكربوهيدرات وزد الألياف.';
      }
      if (avgImpact >= 5) {
        return 'التأثير على السكر مرتفع. أضف المزيد من الخضار والبروتين.';
      }
      if (avgImpact >= 3) {
        return 'التأثير على السكر معتدل. الوجبات جيدة نسبياً.';
      }
      return 'التأثير على السكر منخفض. ممتاز! استمر على هذا النظام.';
    } else {
      if (avgImpact >= 7) {
        return 'Sugar impact is very high. Reduce carbs and increase fiber.';
      }
      if (avgImpact >= 5) {
        return 'Sugar impact is high. Add more vegetables and protein.';
      }
      if (avgImpact >= 3) {
        return 'Sugar impact is moderate. Meals are fairly balanced.';
      }
      return 'Sugar impact is low. Excellent! Keep up this diet.';
    }
  }

  // ── SharedPreferences persistence ─────────────────────────────────────────

  static Future<void> savePreferences(UserFoodPreferences prefs) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('food_prefs', jsonEncode(prefs.toJson()));
  }

  static Future<UserFoodPreferences> loadPreferences() async {
    final sp = await SharedPreferences.getInstance();
    final str = sp.getString('food_prefs');
    if (str == null) return const UserFoodPreferences();
    try {
      return UserFoodPreferences.fromJson(
          jsonDecode(str) as Map<String, dynamic>);
    } catch (_) {
      return const UserFoodPreferences();
    }
  }

  // ── Meal plan templates ───────────────────────────────────────────────────

  static const _plan1 = DailyMealPlan(meals: [
    PlannedMeal(mealType: 'الفطور', foods: [
      FoodItem(nameAr: 'شوفان (50غ جاف)',      nameEn: 'Oats',              calories: 189, carbs: 32,  protein: 6.5, fat: 3.5, sugar: 1,   glycemicIndex: 55, category: 'carb'),
      FoodItem(nameAr: 'بيضة مسلوقة',           nameEn: 'Boiled Egg',        calories: 78,  carbs: 0.6, protein: 6.3, fat: 5.3, sugar: 0.6, glycemicIndex: 0,  category: 'protein'),
      FoodItem(nameAr: 'شاي (كوب)',             nameEn: 'Tea',               calories: 1,   carbs: 0.2, protein: 0,   fat: 0,   sugar: 0,   glycemicIndex: 0,  category: 'drink'),
    ]),
    PlannedMeal(mealType: 'وجبة خفيفة صباحية', foods: [
      FoodItem(nameAr: 'تفاحة متوسطة',          nameEn: 'Apple',             calories: 95,  carbs: 25,  protein: 0.5, fat: 0.3, sugar: 19,  glycemicIndex: 36, category: 'fruit'),
      FoodItem(nameAr: 'مكسرات مشكلة (30غ)',   nameEn: 'Mixed Nuts',        calories: 182, carbs: 6.3, protein: 6,   fat: 16.2,sugar: 1.2, glycemicIndex: 15, category: 'fat'),
    ]),
    PlannedMeal(mealType: 'الغداء', foods: [
      FoodItem(nameAr: 'صدر دجاج مشوي (100غ)', nameEn: 'Grilled Chicken',   calories: 165, carbs: 0,   protein: 31,  fat: 3.6, sugar: 0,   glycemicIndex: 0,  category: 'protein'),
      FoodItem(nameAr: 'عدس مطبوخ (100غ)',      nameEn: 'Cooked Lentils',    calories: 116, carbs: 20,  protein: 9,   fat: 0.4, sugar: 1.8, glycemicIndex: 32, category: 'carb'),
      FoodItem(nameAr: 'سلطة خضراء',            nameEn: 'Green Salad',       calories: 20,  carbs: 3.5, protein: 1.5, fat: 0.2, sugar: 2,   glycemicIndex: 10, category: 'vegetable'),
      FoodItem(nameAr: 'خبز قمح كامل',          nameEn: 'Whole Wheat Bread', calories: 247, carbs: 43,  protein: 13,  fat: 4.2, sugar: 6,   glycemicIndex: 68, category: 'carb'),
    ]),
    PlannedMeal(mealType: 'وجبة خفيفة مسائية', foods: [
      FoodItem(nameAr: 'لبن زبادي قليل الدسم (200مل)', nameEn: 'Low-Fat Yogurt', calories: 100, carbs: 7.7, protein: 8.5, fat: 3.8, sugar: 7.7, glycemicIndex: 36, category: 'dairy'),
    ]),
    PlannedMeal(mealType: 'العشاء', foods: [
      FoodItem(nameAr: 'سمك مشوي (100غ)',       nameEn: 'Grilled Fish',      calories: 136, carbs: 0,   protein: 27,  fat: 3,   sugar: 0,   glycemicIndex: 0,  category: 'protein'),
      FoodItem(nameAr: 'بطاطا حلوة (100غ)',    nameEn: 'Sweet Potato',      calories: 86,  carbs: 20,  protein: 1.6, fat: 0.1, sugar: 4.2, glycemicIndex: 44, category: 'carb'),
      FoodItem(nameAr: 'بروكلي (100غ)',          nameEn: 'Broccoli',         calories: 34,  carbs: 7,   protein: 2.8, fat: 0.4, sugar: 1.7, glycemicIndex: 10, category: 'vegetable'),
    ]),
  ]);

  static const _plan2 = DailyMealPlan(meals: [
    PlannedMeal(mealType: 'الفطور', foods: [
      FoodItem(nameAr: 'خبز قمح كامل',          nameEn: 'Whole Wheat Bread', calories: 247, carbs: 43,  protein: 13,  fat: 4.2, sugar: 6,   glycemicIndex: 68, category: 'carb'),
      FoodItem(nameAr: 'بيضة مسلوقة',           nameEn: 'Boiled Egg',        calories: 78,  carbs: 0.6, protein: 6.3, fat: 5.3, sugar: 0.6, glycemicIndex: 0,  category: 'protein'),
      FoodItem(nameAr: 'زيت زيتون (ملعقة)',     nameEn: 'Olive Oil',         calories: 119, carbs: 0,   protein: 0,   fat: 13.5,sugar: 0,   glycemicIndex: 0,  category: 'fat'),
      FoodItem(nameAr: 'شاي (كوب)',             nameEn: 'Tea',               calories: 1,   carbs: 0.2, protein: 0,   fat: 0,   sugar: 0,   glycemicIndex: 0,  category: 'drink'),
    ]),
    PlannedMeal(mealType: 'وجبة خفيفة صباحية', foods: [
      FoodItem(nameAr: 'برتقال',                nameEn: 'Orange',            calories: 62,  carbs: 15,  protein: 1.2, fat: 0.2, sugar: 12,  glycemicIndex: 43, category: 'fruit'),
      FoodItem(nameAr: 'مكسرات مشكلة (30غ)',   nameEn: 'Mixed Nuts',        calories: 182, carbs: 6.3, protein: 6,   fat: 16.2,sugar: 1.2, glycemicIndex: 15, category: 'fat'),
    ]),
    PlannedMeal(mealType: 'الغداء', foods: [
      FoodItem(nameAr: 'سمك مشوي (100غ)',       nameEn: 'Grilled Fish',      calories: 136, carbs: 0,   protein: 27,  fat: 3,   sugar: 0,   glycemicIndex: 0,  category: 'protein'),
      FoodItem(nameAr: 'عدس مطبوخ (100غ)',      nameEn: 'Cooked Lentils',    calories: 116, carbs: 20,  protein: 9,   fat: 0.4, sugar: 1.8, glycemicIndex: 32, category: 'carb'),
      FoodItem(nameAr: 'سلطة خضراء',            nameEn: 'Green Salad',       calories: 20,  carbs: 3.5, protein: 1.5, fat: 0.2, sugar: 2,   glycemicIndex: 10, category: 'vegetable'),
      FoodItem(nameAr: 'طماطم (100غ)',           nameEn: 'Tomato',            calories: 18,  carbs: 3.9, protein: 0.9, fat: 0.2, sugar: 2.6, glycemicIndex: 15, category: 'vegetable'),
    ]),
    PlannedMeal(mealType: 'وجبة خفيفة مسائية', foods: [
      FoodItem(nameAr: 'لبن زبادي قليل الدسم (200مل)', nameEn: 'Low-Fat Yogurt', calories: 100, carbs: 7.7, protein: 8.5, fat: 3.8, sugar: 7.7, glycemicIndex: 36, category: 'dairy'),
    ]),
    PlannedMeal(mealType: 'العشاء', foods: [
      FoodItem(nameAr: 'صدر دجاج مشوي (100غ)', nameEn: 'Grilled Chicken',   calories: 165, carbs: 0,   protein: 31,  fat: 3.6, sugar: 0,   glycemicIndex: 0,  category: 'protein'),
      FoodItem(nameAr: 'بروكلي (100غ)',          nameEn: 'Broccoli',         calories: 34,  carbs: 7,   protein: 2.8, fat: 0.4, sugar: 1.7, glycemicIndex: 10, category: 'vegetable'),
      FoodItem(nameAr: 'خيار (100غ)',            nameEn: 'Cucumber',          calories: 16,  carbs: 3.6, protein: 0.7, fat: 0.1, sugar: 1.7, glycemicIndex: 15, category: 'vegetable'),
    ]),
  ]);

  static const _plan3 = DailyMealPlan(meals: [
    PlannedMeal(mealType: 'الفطور', foods: [
      FoodItem(nameAr: 'بيضة مسلوقة',           nameEn: 'Boiled Egg',        calories: 78,  carbs: 0.6, protein: 6.3, fat: 5.3, sugar: 0.6, glycemicIndex: 0,  category: 'protein'),
      FoodItem(nameAr: 'جبن (30غ)',              nameEn: 'Cheese',            calories: 120, carbs: 0.4, protein: 7.5, fat: 9.9, sugar: 0.2, glycemicIndex: 0,  category: 'dairy'),
      FoodItem(nameAr: 'شاي (كوب)',             nameEn: 'Tea',               calories: 1,   carbs: 0.2, protein: 0,   fat: 0,   sugar: 0,   glycemicIndex: 0,  category: 'drink'),
    ]),
    PlannedMeal(mealType: 'وجبة خفيفة صباحية', foods: [
      FoodItem(nameAr: 'مكسرات مشكلة (30غ)',   nameEn: 'Mixed Nuts',        calories: 182, carbs: 6.3, protein: 6,   fat: 16.2,sugar: 1.2, glycemicIndex: 15, category: 'fat'),
      FoodItem(nameAr: 'تفاحة متوسطة',          nameEn: 'Apple',             calories: 95,  carbs: 25,  protein: 0.5, fat: 0.3, sugar: 19,  glycemicIndex: 36, category: 'fruit'),
    ]),
    PlannedMeal(mealType: 'الغداء', foods: [
      FoodItem(nameAr: 'صدر دجاج مشوي (100غ)', nameEn: 'Grilled Chicken',   calories: 165, carbs: 0,   protein: 31,  fat: 3.6, sugar: 0,   glycemicIndex: 0,  category: 'protein'),
      FoodItem(nameAr: 'فاصوليا مطبوخة (100غ)',nameEn: 'Cooked Beans',      calories: 127, carbs: 23,  protein: 8.7, fat: 0.5, sugar: 0.4, glycemicIndex: 24, category: 'carb'),
      FoodItem(nameAr: 'سلطة خضراء',            nameEn: 'Green Salad',       calories: 20,  carbs: 3.5, protein: 1.5, fat: 0.2, sugar: 2,   glycemicIndex: 10, category: 'vegetable'),
    ]),
    PlannedMeal(mealType: 'وجبة خفيفة مسائية', foods: [
      FoodItem(nameAr: 'لبن زبادي قليل الدسم (200مل)', nameEn: 'Low-Fat Yogurt', calories: 100, carbs: 7.7, protein: 8.5, fat: 3.8, sugar: 7.7, glycemicIndex: 36, category: 'dairy'),
    ]),
    PlannedMeal(mealType: 'العشاء', foods: [
      FoodItem(nameAr: 'سمك مشوي (100غ)',       nameEn: 'Grilled Fish',      calories: 136, carbs: 0,   protein: 27,  fat: 3,   sugar: 0,   glycemicIndex: 0,  category: 'protein'),
      FoodItem(nameAr: 'بروكلي (100غ)',          nameEn: 'Broccoli',         calories: 34,  carbs: 7,   protein: 2.8, fat: 0.4, sugar: 1.7, glycemicIndex: 10, category: 'vegetable'),
      FoodItem(nameAr: 'طماطم (100غ)',           nameEn: 'Tomato',            calories: 18,  carbs: 3.9, protein: 0.9, fat: 0.2, sugar: 2.6, glycemicIndex: 15, category: 'vegetable'),
    ]),
  ]);

  static const _plan4 = DailyMealPlan(meals: [
    PlannedMeal(mealType: 'الفطور', foods: [
      FoodItem(nameAr: 'شوفان (50غ جاف)',      nameEn: 'Oats',              calories: 189, carbs: 32,  protein: 6.5, fat: 3.5, sugar: 1,   glycemicIndex: 55, category: 'carb'),
      FoodItem(nameAr: 'حليب قليل الدسم (200مل)', nameEn: 'Low-Fat Milk',  calories: 92,  carbs: 9.6, protein: 6.4, fat: 2.5, sugar: 10,  glycemicIndex: 32, category: 'dairy'),
      FoodItem(nameAr: 'شاي (كوب)',             nameEn: 'Tea',               calories: 1,   carbs: 0.2, protein: 0,   fat: 0,   sugar: 0,   glycemicIndex: 0,  category: 'drink'),
    ]),
    PlannedMeal(mealType: 'وجبة خفيفة صباحية', foods: [
      FoodItem(nameAr: 'تفاحة متوسطة',          nameEn: 'Apple',             calories: 95,  carbs: 25,  protein: 0.5, fat: 0.3, sugar: 19,  glycemicIndex: 36, category: 'fruit'),
    ]),
    PlannedMeal(mealType: 'الغداء', foods: [
      FoodItem(nameAr: 'عدس مطبوخ (100غ)',      nameEn: 'Cooked Lentils',    calories: 116, carbs: 20,  protein: 9,   fat: 0.4, sugar: 1.8, glycemicIndex: 32, category: 'carb'),
      FoodItem(nameAr: 'فاصوليا مطبوخة (100غ)',nameEn: 'Cooked Beans',      calories: 127, carbs: 23,  protein: 8.7, fat: 0.5, sugar: 0.4, glycemicIndex: 24, category: 'carb'),
      FoodItem(nameAr: 'سلطة خضراء',            nameEn: 'Green Salad',       calories: 20,  carbs: 3.5, protein: 1.5, fat: 0.2, sugar: 2,   glycemicIndex: 10, category: 'vegetable'),
      FoodItem(nameAr: 'خيار (100غ)',            nameEn: 'Cucumber',          calories: 16,  carbs: 3.6, protein: 0.7, fat: 0.1, sugar: 1.7, glycemicIndex: 15, category: 'vegetable'),
    ]),
    PlannedMeal(mealType: 'وجبة خفيفة مسائية', foods: [
      FoodItem(nameAr: 'لبن زبادي قليل الدسم (200مل)', nameEn: 'Low-Fat Yogurt', calories: 100, carbs: 7.7, protein: 8.5, fat: 3.8, sugar: 7.7, glycemicIndex: 36, category: 'dairy'),
      FoodItem(nameAr: 'مكسرات مشكلة (30غ)',   nameEn: 'Mixed Nuts',        calories: 182, carbs: 6.3, protein: 6,   fat: 16.2,sugar: 1.2, glycemicIndex: 15, category: 'fat'),
    ]),
    PlannedMeal(mealType: 'العشاء', foods: [
      FoodItem(nameAr: 'سمك مشوي (100غ)',       nameEn: 'Grilled Fish',      calories: 136, carbs: 0,   protein: 27,  fat: 3,   sugar: 0,   glycemicIndex: 0,  category: 'protein'),
      FoodItem(nameAr: 'بطاطا حلوة (100غ)',    nameEn: 'Sweet Potato',      calories: 86,  carbs: 20,  protein: 1.6, fat: 0.1, sugar: 4.2, glycemicIndex: 44, category: 'carb'),
      FoodItem(nameAr: 'بروكلي (100غ)',          nameEn: 'Broccoli',         calories: 34,  carbs: 7,   protein: 2.8, fat: 0.4, sugar: 1.7, glycemicIndex: 10, category: 'vegetable'),
    ]),
  ]);

  static const _plan5 = DailyMealPlan(meals: [
    PlannedMeal(mealType: 'الفطور', foods: [
      FoodItem(nameAr: 'خبز قمح كامل',          nameEn: 'Whole Wheat Bread', calories: 247, carbs: 43,  protein: 13,  fat: 4.2, sugar: 6,   glycemicIndex: 68, category: 'carb'),
      FoodItem(nameAr: 'جبن (30غ)',              nameEn: 'Cheese',            calories: 120, carbs: 0.4, protein: 7.5, fat: 9.9, sugar: 0.2, glycemicIndex: 0,  category: 'dairy'),
      FoodItem(nameAr: 'بيضة مسلوقة',           nameEn: 'Boiled Egg',        calories: 78,  carbs: 0.6, protein: 6.3, fat: 5.3, sugar: 0.6, glycemicIndex: 0,  category: 'protein'),
      FoodItem(nameAr: 'قهوة بدون سكر',         nameEn: 'Black Coffee',      calories: 2,   carbs: 0,   protein: 0.3, fat: 0,   sugar: 0,   glycemicIndex: 0,  category: 'drink'),
    ]),
    PlannedMeal(mealType: 'وجبة خفيفة صباحية', foods: [
      FoodItem(nameAr: 'تمر (3 حبات)',           nameEn: 'Dates',             calories: 69,  carbs: 18.6,protein: 0.6, fat: 0,   sugar: 16.8,glycemicIndex: 42, category: 'fruit'),
      FoodItem(nameAr: 'مكسرات مشكلة (30غ)',   nameEn: 'Mixed Nuts',        calories: 182, carbs: 6.3, protein: 6,   fat: 16.2,sugar: 1.2, glycemicIndex: 15, category: 'fat'),
    ]),
    PlannedMeal(mealType: 'الغداء', foods: [
      FoodItem(nameAr: 'صدر دجاج مشوي (100غ)', nameEn: 'Grilled Chicken',   calories: 165, carbs: 0,   protein: 31,  fat: 3.6, sugar: 0,   glycemicIndex: 0,  category: 'protein'),
      FoodItem(nameAr: 'معكرونة مسلوقة (100غ)',nameEn: 'Cooked Pasta',      calories: 158, carbs: 31,  protein: 5.8, fat: 0.9, sugar: 0.6, glycemicIndex: 55, category: 'carb'),
      FoodItem(nameAr: 'سلطة خضراء',            nameEn: 'Green Salad',       calories: 20,  carbs: 3.5, protein: 1.5, fat: 0.2, sugar: 2,   glycemicIndex: 10, category: 'vegetable'),
    ]),
    PlannedMeal(mealType: 'وجبة خفيفة مسائية', foods: [
      FoodItem(nameAr: 'برتقال',                nameEn: 'Orange',            calories: 62,  carbs: 15,  protein: 1.2, fat: 0.2, sugar: 12,  glycemicIndex: 43, category: 'fruit'),
    ]),
    PlannedMeal(mealType: 'العشاء', foods: [
      FoodItem(nameAr: 'سمك مشوي (100غ)',       nameEn: 'Grilled Fish',      calories: 136, carbs: 0,   protein: 27,  fat: 3,   sugar: 0,   glycemicIndex: 0,  category: 'protein'),
      FoodItem(nameAr: 'عدس مطبوخ (100غ)',      nameEn: 'Cooked Lentils',    calories: 116, carbs: 20,  protein: 9,   fat: 0.4, sugar: 1.8, glycemicIndex: 32, category: 'carb'),
      FoodItem(nameAr: 'طماطم (100غ)',           nameEn: 'Tomato',            calories: 18,  carbs: 3.9, protein: 0.9, fat: 0.2, sugar: 2.6, glycemicIndex: 15, category: 'vegetable'),
      FoodItem(nameAr: 'خيار (100غ)',            nameEn: 'Cucumber',          calories: 16,  carbs: 3.6, protein: 0.7, fat: 0.1, sugar: 1.7, glycemicIndex: 15, category: 'vegetable'),
    ]),
  ]);

  static const _plans = [_plan1, _plan2, _plan3, _plan4, _plan5];

  // ── Personalized plan generation ─────────────────────────────────────────

  static const _vegetarianExcluded = ['Chicken', 'Fish', 'Beef', 'Shrimp', 'Tuna'];

  static List<FoodItem> _applyFilters(
      List<FoodItem> items, UserFoodPreferences prefs, double riskScore) {
    var pool = items.where((f) {
      // Filter disliked foods
      if (prefs.dislikedFoods.contains(f.nameAr)) return false;
      // Vegetarian: exclude meat/fish from protein category
      if (prefs.dietType == 'vegetarian' && f.category == 'protein') {
        for (final excl in _vegetarianExcluded) {
          if (f.nameEn.contains(excl)) return false;
        }
      }
      // Kidney issues
      if (prefs.hasKidneyIssues && !f.suitableForKidney) return false;
      // Heart issues
      if (prefs.hasHeartIssues && !f.suitableForHeart) return false;
      return true;
    }).toList();

    // GI filtering based on risk score
    if (riskScore > 0.7) {
      final strict = pool.where((f) => f.glycemicIndex < 55 || f.glycemicIndex == 0).toList();
      if (strict.isNotEmpty) pool = strict;
    } else if (riskScore > 0.4) {
      final moderate = pool.where((f) => f.glycemicIndex < 65 || f.glycemicIndex == 0).toList();
      if (moderate.isNotEmpty) pool = moderate;
    }

    return pool;
  }

  static FoodItem? _pickFrom(
    List<FoodItem> pool,
    String category,
    Set<String> used,
    List<String> likedFoods,
    Random rng,
  ) {
    var candidates = pool
        .where((f) => f.category == category && !used.contains(f.nameAr))
        .toList();
    if (candidates.isEmpty) return null;

    // Prefer liked foods if any
    if (likedFoods.isNotEmpty) {
      final liked = candidates.where((f) => likedFoods.contains(f.nameAr)).toList();
      if (liked.isNotEmpty) {
        final pick = liked[rng.nextInt(liked.length)];
        used.add(pick.nameAr);
        return pick;
      }
    }

    final pick = candidates[rng.nextInt(candidates.length)];
    used.add(pick.nameAr);
    return pick;
  }

  static FoodItem? _pickFromCategories(
    List<FoodItem> pool,
    List<String> categories,
    Set<String> used,
    List<String> likedFoods,
    Random rng,
  ) {
    for (final cat in categories) {
      final pick = _pickFrom(pool, cat, used, likedFoods, rng);
      if (pick != null) return pick;
    }
    // Fallback: any unused item with lowest GI
    final fallback = pool
        .where((f) => !used.contains(f.nameAr))
        .toList()
      ..sort((a, b) => a.glycemicIndex.compareTo(b.glycemicIndex));
    if (fallback.isEmpty) return null;
    final pick = fallback.first;
    used.add(pick.nameAr);
    return pick;
  }

  static DailyMealPlan generatePersonalizedPlan(
      UserFoodPreferences prefs, double riskScore) {
    final rng = Random();
    final pool = _applyFilters(List.from(_foodItems), prefs, riskScore);
    final used = <String>{};
    final liked = prefs.likedFoods;

    // ── Breakfast: 1 carb + 1 protein + 1 drink ──────────────────────────
    final breakfastFoods = <FoodItem>[];
    final bCarb = _pickFrom(pool, 'carb', used, liked, rng);
    if (bCarb != null) breakfastFoods.add(bCarb);
    final bProt = _pickFrom(pool, 'protein', used, liked, rng);
    if (bProt != null) breakfastFoods.add(bProt);
    final bDrink = _pickFrom(pool, 'drink', used, liked, rng);
    if (bDrink != null) breakfastFoods.add(bDrink);

    // ── Morning snack: 1-2 fruits or dairy ───────────────────────────────
    final morningFoods = <FoodItem>[];
    final ms1 = _pickFromCategories(pool, ['fruit', 'dairy'], used, liked, rng);
    if (ms1 != null) morningFoods.add(ms1);
    // Optionally add a fat (nuts)
    if (rng.nextBool()) {
      final ms2 = _pickFrom(pool, 'fat', used, liked, rng);
      if (ms2 != null) morningFoods.add(ms2);
    }

    // ── Lunch: 1-2 proteins + 1-2 carbs + 1-2 vegetables ────────────────
    final lunchFoods = <FoodItem>[];
    final lProt1 = _pickFrom(pool, 'protein', used, liked, rng);
    if (lProt1 != null) lunchFoods.add(lProt1);
    if (rng.nextBool()) {
      final lProt2 = _pickFrom(pool, 'protein', used, liked, rng);
      if (lProt2 != null) lunchFoods.add(lProt2);
    }
    final lCarb1 = _pickFrom(pool, 'carb', used, liked, rng);
    if (lCarb1 != null) lunchFoods.add(lCarb1);
    if (rng.nextBool()) {
      final lCarb2 = _pickFrom(pool, 'carb', used, liked, rng);
      if (lCarb2 != null) lunchFoods.add(lCarb2);
    }
    final lVeg1 = _pickFrom(pool, 'vegetable', used, liked, rng);
    if (lVeg1 != null) lunchFoods.add(lVeg1);
    if (rng.nextBool()) {
      final lVeg2 = _pickFrom(pool, 'vegetable', used, liked, rng);
      if (lVeg2 != null) lunchFoods.add(lVeg2);
    }

    // ── Afternoon snack: 1 dairy/fruit/fat ───────────────────────────────
    final afternoonFoods = <FoodItem>[];
    final as1 = _pickFromCategories(pool, ['dairy', 'fruit', 'fat'], used, liked, rng);
    if (as1 != null) afternoonFoods.add(as1);

    // ── Dinner: 1 protein + 1 vegetable + optionally 1 carb ──────────────
    final dinnerFoods = <FoodItem>[];
    final dProt = _pickFrom(pool, 'protein', used, liked, rng);
    if (dProt != null) dinnerFoods.add(dProt);
    final dVeg = _pickFrom(pool, 'vegetable', used, liked, rng);
    if (dVeg != null) dinnerFoods.add(dVeg);
    if (rng.nextBool()) {
      final dCarb = _pickFrom(pool, 'carb', used, liked, rng);
      if (dCarb != null) dinnerFoods.add(dCarb);
    }

    // Build plan — ensure each meal has at least one item via fallback
    final meals = <PlannedMeal>[];

    if (breakfastFoods.isNotEmpty) {
      meals.add(PlannedMeal(mealType: 'الفطور', foods: breakfastFoods));
    }
    if (morningFoods.isNotEmpty) {
      meals.add(PlannedMeal(mealType: 'وجبة خفيفة صباحية', foods: morningFoods));
    }
    if (lunchFoods.isNotEmpty) {
      meals.add(PlannedMeal(mealType: 'الغداء', foods: lunchFoods));
    }
    if (afternoonFoods.isNotEmpty) {
      meals.add(PlannedMeal(mealType: 'وجبة خفيفة مسائية', foods: afternoonFoods));
    }
    if (dinnerFoods.isNotEmpty) {
      meals.add(PlannedMeal(mealType: 'العشاء', foods: dinnerFoods));
    }

    // Fallback: if nothing generated at all, use a template
    if (meals.isEmpty) return _plans[rng.nextInt(_plans.length)];

    return DailyMealPlan(meals: meals);
  }

  static DailyMealPlan generateDailyPlan(
      {UserFoodPreferences? prefs, double riskScore = 0.0}) {
    if (prefs != null &&
        (prefs.likedFoods.isNotEmpty ||
            prefs.dislikedFoods.isNotEmpty ||
            prefs.hasKidneyIssues ||
            prefs.hasHeartIssues ||
            prefs.dietType != 'mixed' ||
            riskScore > 0.0)) {
      return generatePersonalizedPlan(prefs, riskScore);
    }
    return _plans[Random().nextInt(_plans.length)];
  }

  static DailyMealPlan generateMealPlan() => generateDailyPlan();

  // ── Legacy helpers ────────────────────────────────────────────────────────

  static double calculateGlucoseImpact({
    required double carbs,
    required double fiber,
  }) {
    final netCarbs = (carbs - fiber).clamp(0.0, double.infinity);
    return ((60.0 * netCarbs) / 100.0 / 10.0).clamp(0.0, 10.0);
  }

  static DailySummary computeSummary(List<MealEntry> meals) {
    if (meals.isEmpty) {
      return const DailySummary(
        totalCalories: 0,
        totalCarbs: 0,
        totalProtein: 0,
        totalFat: 0,
        totalFiber: 0,
        avgGlucoseImpact: 0,
        mealCount: 0,
        meals: [],
      );
    }
    double cal = 0, carbs = 0, prot = 0, fat = 0, fiber = 0, gl = 0;
    for (final m in meals) {
      cal += m.calories;
      carbs += m.carbs;
      prot += m.protein;
      fat += m.fat;
      fiber += m.fiber;
      gl += m.glucoseImpact;
    }
    return DailySummary(
      totalCalories: cal,
      totalCarbs: carbs,
      totalProtein: prot,
      totalFat: fat,
      totalFiber: fiber,
      avgGlucoseImpact: gl / meals.length,
      mealCount: meals.length,
      meals: meals,
    );
  }
}
