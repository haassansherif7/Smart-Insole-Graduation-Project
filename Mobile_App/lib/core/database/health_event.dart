import 'package:uuid/uuid.dart';

enum EventType { sensorScan, imageAnalysis, strokePrediction, generalHealth }

enum RiskLevel { none, info, warning, critical }

class HealthEvent {
  final String id;
  final EventType eventType;
  final double riskScore;
  final RiskLevel riskLevel;
  final DateTime timestamp;
  final String? notes;
  final String? userId;

  HealthEvent({
    String? id,
    required this.eventType,
    required this.riskScore,
    required this.riskLevel,
    DateTime? timestamp,
    this.notes,
    this.userId,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'event_type': eventType.index,
        'risk_score': riskScore,
        'risk_level': riskLevel.index,
        'timestamp': timestamp.toIso8601String(),
        'notes': notes,
        'user_id': userId,
      };

  factory HealthEvent.fromMap(Map<String, dynamic> map) => HealthEvent(
        id: map['id'] as String,
        eventType: EventType.values[(map['event_type'] as int?) ?? 0],
        riskScore: (map['risk_score'] as num?)?.toDouble() ?? 0.0,
        riskLevel: RiskLevel.values[(map['risk_level'] as int?) ?? 0],
        timestamp: DateTime.parse(map['timestamp'] as String),
        notes: map['notes'] as String?,
        userId: map['user_id'] as String?,
      );

  HealthEvent copyWith({
    EventType? eventType,
    double? riskScore,
    RiskLevel? riskLevel,
    DateTime? timestamp,
    String? notes,
    String? userId,
  }) =>
      HealthEvent(
        id: id,
        eventType: eventType ?? this.eventType,
        riskScore: riskScore ?? this.riskScore,
        riskLevel: riskLevel ?? this.riskLevel,
        timestamp: timestamp ?? this.timestamp,
        notes: notes ?? this.notes,
        userId: userId ?? this.userId,
      );
}
