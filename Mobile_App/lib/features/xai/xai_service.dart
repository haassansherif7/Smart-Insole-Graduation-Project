import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class XaiService {
  static const _baseUrl = 'http://10.0.2.2:8000';

  Future<Map<String, dynamic>?> explain({
    required String eventType,
    required double riskScore,
    required String riskLevel,
    String? notes,
    bool isArabic = true,
  }) async {
    try {
      debugPrint('=== XAI: Calling $_baseUrl/xai ===');
      debugPrint('=== XAI: isArabic=$isArabic, type=$eventType, score=$riskScore ===');

      final res = await http.post(
        Uri.parse('$_baseUrl/xai'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'event_type': eventType,
          'risk_score': riskScore,
          'risk_level': riskLevel,
          'notes': notes ?? '',
          'language': isArabic ? 'ar' : 'en',
        }),
      ).timeout(const Duration(seconds: 60));

      debugPrint('=== XAI: Status = ${res.statusCode} ===');
      debugPrint('=== XAI: Body = ${res.body} ===');

      if (res.statusCode != 200) return null;

      final decoded = utf8.decode(res.bodyBytes);
      final data = jsonDecode(decoded) as Map<String, dynamic>;

      if (data.containsKey('error')) {
        debugPrint('=== XAI: Server error = ${data['error']} ===');
        return null;
      }
      return data;
    } on TimeoutException {
      debugPrint('=== XAI: TIMEOUT after 60s ===');
      return null;
    } catch (e, stack) {
      debugPrint('=== XAI ERROR: $e ===');
      debugPrint('=== XAI STACK: $stack ===');
      return null;
    }
  }
}
