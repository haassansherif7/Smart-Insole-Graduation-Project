import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:diabetes_project/core/config/app_config.dart';

class XaiService {
  Future<Map<String, dynamic>?> explain({
    required String eventType,
    required double riskScore,
    required String riskLevel,
    String? notes,
    bool isArabic = true,
  }) async {
    final body = jsonEncode({
      'event_type': eventType,
      'risk_score': riskScore,
      'risk_level': riskLevel,
      'notes': notes ?? '',
      'language': isArabic ? 'ar' : 'en',
    });

    // Try Railway first
    try {
      debugPrint('=== XAI: Trying Railway ===');
      final res = await http.post(
        Uri.parse('${AppConfig.railwayUrl}/xai'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 60));
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        if (!data.containsKey('error')) return data;
      }
    } catch (e) {
      debugPrint('=== XAI: Railway failed: $e ===');
    }

    // Fallback to local
    try {
      debugPrint('=== XAI: Trying Local ===');
      final res = await http.post(
        Uri.parse('${AppConfig.localUrl}/xai'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 60));
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        if (!data.containsKey('error')) return data;
      }
    } catch (e) {
      debugPrint('=== XAI: Local failed: $e ===');
    }

    return null;
  }
}
