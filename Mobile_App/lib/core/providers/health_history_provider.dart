import 'package:flutter/foundation.dart';
import 'package:diabetes_project/core/database/health_event.dart';
import 'package:diabetes_project/core/database/health_event_repository.dart';
import 'package:diabetes_project/core/alerts/alert_engine.dart';
import 'package:diabetes_project/core/alerts/alert_notifier.dart';

class HealthHistoryProvider extends ChangeNotifier {
  final HealthEventRepository _repo;
  final AlertEngine _engine;
  final AlertNotifier _notifier;

  Map<EventType, HealthEvent?> _latest = {};
  final Map<EventType, List<HealthEvent>> _history = {};
  final Map<EventType, double> _slopes = {};
  AlertResult? _currentAlert;
  bool _loading = false;
  String? _error;
  bool _isArabic = true;

  HealthHistoryProvider({
    HealthEventRepository? repo,
    AlertEngine? engine,
    AlertNotifier? notifier,
  })  : _repo = repo ?? HealthEventRepository(),
        _engine = engine ?? AlertEngine(),
        _notifier = notifier ?? AlertNotifier();

  Map<EventType, HealthEvent?> get latest => _latest;
  Map<EventType, List<HealthEvent>> get history => _history;
  Map<EventType, double> get slopes => _slopes;
  AlertResult? get currentAlert => _currentAlert;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadDashboardData({bool isArabic = true}) async {
    _isArabic = isArabic;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _latest = await _repo.getLatestPerType();
      for (final type in EventType.values) {
        _history[type] = await _repo.getLast7Days(type);
        _slopes[type] = await _repo.getTrendSlope(type);
      }
      _evaluateAlert(isArabic: isArabic);
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> saveAndRefresh(HealthEvent event) async {
    final previousScore = _latest[event.eventType]?.riskScore ?? 0.0;
    final scoreDiff = (event.riskScore - previousScore).abs();

    // Always save to database
    await _repo.save(event);

    // Refresh latest data
    _latest = await _repo.getLatestPerType();
    for (final type in EventType.values) {
      _history[type] = await _repo.getLast7Days(type);
      _slopes[type]  = await _repo.getTrendSlope(type);
    }

    // Only re-evaluate alert if score changed meaningfully (>5%)
    // OR if no current alert yet
    if (scoreDiff > 0.05 || _currentAlert == null) {
      _evaluateAlert(isArabic: _isArabic);
    }

    notifyListeners();
  }

  Future<void> saveEventAndRefresh({
    required EventType type,
    required double riskScore,
    required RiskLevel riskLevel,
    String? notes,
  }) async {
    await saveAndRefresh(
      HealthEvent(
        eventType: type,
        riskScore: riskScore,
        riskLevel: riskLevel,
        notes: notes,
      ),
    );
  }

  void _evaluateAlert({bool isArabic = true}) {
    double maxScore = 0;
    double maxSlope = 0;
    EventType? worstType;

    for (final type in EventType.values) {
      final event = _latest[type];
      if (event != null && event.riskScore > maxScore) {
        maxScore = event.riskScore;
        maxSlope = _slopes[type] ?? 0;
        worstType = type;
      }
    }

    _currentAlert = _engine.evaluate(
      riskScore: maxScore,
      trendSlope: maxSlope,
      eventType: worstType,
      isArabic: isArabic,
    );

    debugPrint('=== ALERT: score=$maxScore, level=${_currentAlert?.level} ===');

    if (_currentAlert != null) {
      if (_currentAlert!.level == AlertLevel.warning ||
          _currentAlert!.level == AlertLevel.critical) {
        _notifier.notify(_currentAlert!, isArabic: isArabic);
      } else {
        // Risk went down → cancel ongoing notifications
        _notifier.cancelIfSafe(_currentAlert!.level);
      }
    }
  }

  List<HealthEvent> historyFor(EventType type) => _history[type] ?? [];
  double slopeFor(EventType type) => _slopes[type] ?? 0.0;
  HealthEvent? latestFor(EventType type) => _latest[type];
}
