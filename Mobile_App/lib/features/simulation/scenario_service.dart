import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

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
    for (int attempt = 1; attempt <= 2; attempt++) {
      try {
        debugPrint('=== SCENARIO: Attempt $attempt ===');

        final res = await http.post(
          Uri.parse('http://10.0.2.2:8000/scenario'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'foot_risk': patientData['footRisk'] ?? 0.0,
            'grade': patientData['grade'] ?? '',
            'last_scan': patientData['lastScan'] ?? '',
            'language': isArabic ? 'ar' : 'en',
          }),
        ).timeout(const Duration(seconds: 60));

        debugPrint('=== SCENARIO: Status = ${res.statusCode} ===');

        if (res.statusCode != 200) continue;

        final body = utf8.decode(res.bodyBytes);
        final data = jsonDecode(body) as Map<String, dynamic>;

        if (data.containsKey('error')) {
          debugPrint('=== SCENARIO: Server error = ${data['error']} ===');
          continue;
        }

        return ScenarioResult.fromJson(data);
      } catch (e) {
        debugPrint('=== SCENARIO ERROR attempt $attempt: $e ===');
        if (attempt == 2) return null;
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    return null;
  }

}
