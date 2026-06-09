import '../database/health_event.dart';

enum AlertLevel { none, info, warning, critical }

class AlertResult {
  final AlertLevel level;
  final String arabicMessage;
  final double score;
  final double trend;

  const AlertResult({
    required this.level,
    required this.arabicMessage,
    required this.score,
    required this.trend,
  });
}

class AlertEngine {
  AlertResult evaluate({
    required double riskScore,
    required double trendSlope,
    EventType? eventType,
    bool isArabic = true,
  }) {
    final level = _level(riskScore, trendSlope);
    return AlertResult(
      level: level,
      arabicMessage: _buildMessage(level, riskScore, trendSlope, eventType, isArabic),
      score: riskScore,
      trend: trendSlope,
    );
  }

  AlertLevel _level(double score, double slope) {
    if (score >= 0.8 || (score >= 0.65 && slope > 0.05)) {
      return AlertLevel.critical;
    }
    if (score >= 0.55 || (score >= 0.4 && slope > 0.03)) {
      return AlertLevel.warning;
    }
    if (score >= 0.25) return AlertLevel.info;
    return AlertLevel.none;
  }

  String _buildMessage(
      AlertLevel level, double score, double slope, EventType? type, bool isArabic) {
    final pct = (score * 100).toInt();
    final t = _typeName(type, isArabic);
    if (isArabic) {
      final trend = slope > 0.01 ? 'متزايد' : slope < -0.01 ? 'متناقص' : 'مستقر';
      switch (level) {
        case AlertLevel.critical:
          return 'تحذير حرج$t: $pct% ($trend) - راجع طبيبك فوراً';
        case AlertLevel.warning:
          return 'تحذير$t: $pct% ($trend) - انتبه لصحتك';
        case AlertLevel.info:
          return 'تنبيه$t: $pct% ($trend) - راقب وضعك';
        case AlertLevel.none:
          return 'الوضع طبيعي$t: $pct% ($trend)';
      }
    } else {
      final trend = slope > 0.01 ? 'rising' : slope < -0.01 ? 'decreasing' : 'stable';
      switch (level) {
        case AlertLevel.critical:
          return 'Critical$t: $pct% ($trend) - See your doctor immediately';
        case AlertLevel.warning:
          return 'Warning$t: $pct% ($trend) - Pay attention to your health';
        case AlertLevel.info:
          return 'Notice$t: $pct% ($trend) - Monitor your condition';
        case AlertLevel.none:
          return 'Normal$t: $pct% ($trend)';
      }
    }
  }

  String _typeName(EventType? type, bool isArabic) {
    if (type == null) return '';
    if (isArabic) {
      switch (type) {
        case EventType.sensorScan:
          return ' (الاستشعار)';
        case EventType.imageAnalysis:
          return ' (تحليل الصورة)';
        case EventType.strokePrediction:
          return ' (السكتة الدماغية)';
        case EventType.generalHealth:
          return ' (الصحة العامة)';
      }
    } else {
      switch (type) {
        case EventType.sensorScan:
          return ' (Sensor)';
        case EventType.imageAnalysis:
          return ' (Image Analysis)';
        case EventType.strokePrediction:
          return ' (Stroke)';
        case EventType.generalHealth:
          return ' (General Health)';
      }
    }
  }

  RiskLevel scoreToRiskLevel(double score) {
    if (score >= 0.8) return RiskLevel.critical;
    if (score >= 0.55) return RiskLevel.warning;
    if (score >= 0.25) return RiskLevel.info;
    return RiskLevel.none;
  }
}
