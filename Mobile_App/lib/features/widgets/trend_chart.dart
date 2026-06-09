import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:diabetes_project/core/database/health_event.dart';
import 'package:diabetes_project/core/providers/health_history_provider.dart';
import 'package:diabetes_project/main.dart';

class TrendChart extends StatefulWidget {
  const TrendChart({super.key});

  @override
  State<TrendChart> createState() => _TrendChartState();
}

class _TrendChartState extends State<TrendChart> {
  EventType _selected = EventType.sensorScan;

  static const _colors = {
    EventType.sensorScan: Color(0xFF4C6FFF),
    EventType.imageAnalysis: Color(0xFF9C27B0),
    EventType.strokePrediction: Color(0xFFD32F2F),
    EventType.generalHealth: Color(0xFF388E3C),
  };

  static const _texts = {
    'chartTitle': {'ar': 'الاتجاه (7 أيام)', 'en': 'Trend (7 days)'},
    'noData': {'ar': 'لا توجد بيانات كافية', 'en': 'Not enough data'},
  };

  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<AppSettings>(context).locale.languageCode == 'ar';
    final lang = isArabic ? 'ar' : 'en';
    final provider = context.watch<HealthHistoryProvider>();
    final events = provider.historyFor(_selected);
    final color = _colors[_selected]!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _texts['chartTitle']![lang]!,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                DropdownButton<EventType>(
                  value: _selected,
                  underline: const SizedBox(),
                  isDense: true,
                  items: EventType.values
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(_label(t, lang),
                                style: const TextStyle(fontSize: 13)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selected = v!),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: events.isEmpty
                  ? Center(
                      child: Text(
                        _texts['noData']![lang]!,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : LineChart(_buildChart(events, color)),
            ),
            if (events.isNotEmpty) ...[
              const SizedBox(height: 8),
              _TrendIndicator(slope: provider.slopeFor(_selected)),
            ],
          ],
        ),
      ),
    );
  }

  LineChartData _buildChart(List<HealthEvent> events, Color color) {
    final spots = events
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.riskScore * 100))
        .toList();

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (v) =>
            FlLine(color: Colors.grey.withValues(alpha: 0.2), strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 38,
            getTitlesWidget: (v, _) => Text(
              '${v.toInt()}%',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, _) => Text(
              '${v.toInt() + 1}',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ),
        ),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      minY: 0,
      maxY: 100,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: color,
          barWidth: 2.5,
          dotData: FlDotData(
            getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
              radius: 3,
              color: color,
              strokeWidth: 1.5,
              strokeColor: Colors.white,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            color: color.withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }

  String _label(EventType t, String lang) => switch (t) {
        EventType.sensorScan => lang == 'ar' ? 'الاستشعار' : 'Sensor',
        EventType.imageAnalysis => lang == 'ar' ? 'الصورة' : 'Image',
        EventType.strokePrediction => lang == 'ar' ? 'السكتة' : 'Stroke',
        EventType.generalHealth => lang == 'ar' ? 'الصحة' : 'Health',
      };
}

class _TrendIndicator extends StatelessWidget {
  final double slope;
  const _TrendIndicator({required this.slope});

  static const _texts = {
    'up': {'ar': 'الاتجاه متزايد', 'en': 'Trending up'},
    'down': {'ar': 'الاتجاه متناقص', 'en': 'Trending down'},
    'stable': {'ar': 'الاتجاه مستقر', 'en': 'Stable trend'},
  };

  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<AppSettings>(context).locale.languageCode == 'ar';
    final lang = isArabic ? 'ar' : 'en';
    final isUp = slope > 0.01;
    final isDown = slope < -0.01;

    return Row(
      children: [
        Icon(
          isUp
              ? Icons.trending_up
              : isDown
                  ? Icons.trending_down
                  : Icons.trending_flat,
          size: 16,
          color: isUp
              ? const Color(0xFFD32F2F)
              : isDown
                  ? const Color(0xFF388E3C)
                  : Colors.grey,
        ),
        const SizedBox(width: 4),
        Text(
          isUp
              ? _texts['up']![lang]!
              : isDown
                  ? _texts['down']![lang]!
                  : _texts['stable']![lang]!,
          style: TextStyle(
            fontSize: 12,
            color: isUp
                ? const Color(0xFFD32F2F)
                : isDown
                    ? const Color(0xFF388E3C)
                    : Colors.grey,
          ),
        ),
      ],
    );
  }
}
