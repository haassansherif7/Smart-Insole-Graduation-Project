import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:diabetes_project/core/config/app_config.dart';

class ScenarioDetails {
  final String week;
  final String month;
  final List<String> tips;

  const ScenarioDetails({
    required this.week,
    required this.month,
    required this.tips,
  });

  factory ScenarioDetails.fromJson(Map<String, dynamic> json) =>
      ScenarioDetails(
        week: json['week'] as String? ?? '',
        month: json['month'] as String? ?? '',
        tips: (json['tips'] as List?)?.cast<String>() ?? [],
      );
}

class ScenarioResult {
  final ScenarioDetails worst;
  final ScenarioDetails medium;
  final ScenarioDetails best;

  const ScenarioResult({
    required this.worst,
    required this.medium,
    required this.best,
  });

  factory ScenarioResult.fromJson(Map<String, dynamic> json) => ScenarioResult(
        worst: ScenarioDetails.fromJson(json['worst'] as Map<String, dynamic>),
        medium: ScenarioDetails.fromJson(json['medium'] as Map<String, dynamic>),
        best: ScenarioDetails.fromJson(json['best'] as Map<String, dynamic>),
      );
}

class ScenarioService {
  String buildScenarioPrompt(Map<String, dynamic> patientData, {bool isArabic = true}) {
    if (isArabic) {
      return """
أنت نظام محاكاة طبية لمريض سكري.
بيانات المريض:
- درجة خطر القدم: ${patientData['footRisk']}%
- درجة القرحة: ${patientData['grade']}
- آخر فحص: ${patientData['lastScan']}

اعطني 3 سيناريوهات مستقبلية.
أجب بـ JSON فقط بدون أي نص إضافي:
{
  "worst": {"week": "...", "month": "...", "tips": ["...", "...", "..."]},
  "medium": {"week": "...", "month": "...", "tips": ["...", "...", "..."]},
  "best": {"week": "...", "month": "...", "tips": ["...", "...", "..."]}
}
""";
    } else {
      return """
You are a medical simulation system for a diabetic patient.
Patient data:
- Foot risk level: ${patientData['footRisk']}%
- Ulcer grade: ${patientData['grade']}
- Last scan: ${patientData['lastScan']}

Give me 3 future scenarios.
Reply in JSON only with no extra text:
{
  "worst": {"week": "...", "month": "...", "tips": ["...", "...", "..."]},
  "medium": {"week": "...", "month": "...", "tips": ["...", "...", "..."]},
  "best": {"week": "...", "month": "...", "tips": ["...", "...", "..."]}
}
""";
    }
  }

  Future<ScenarioResult?> simulate(
    Map<String, dynamic> patientData, {
    bool isArabic = true,
  }) async {
    final body = jsonEncode({
      'foot_risk': patientData['footRisk'] ?? 0.0,
      'grade': patientData['grade'] ?? '',
      'last_scan': patientData['lastScan'] ?? '',
      'language': isArabic ? 'ar' : 'en',
    });

    // Try Railway first
    try {
      debugPrint('=== SCENARIO: Trying Railway ===');
      final res = await http.post(
        Uri.parse('${AppConfig.railwayUrl}/scenario'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 60));
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        if (!data.containsKey('error')) return ScenarioResult.fromJson(data);
      }
    } catch (e) {
      debugPrint('=== SCENARIO: Railway failed: $e ===');
    }

    // Fallback to local
    try {
      debugPrint('=== SCENARIO: Trying Local ===');
      final res = await http.post(
        Uri.parse('${AppConfig.localUrl}/scenario'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 60));
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        if (!data.containsKey('error')) return ScenarioResult.fromJson(data);
      }
    } catch (e) {
      debugPrint('=== SCENARIO: Local failed: $e ===');
    }

    return null;
  }

}
