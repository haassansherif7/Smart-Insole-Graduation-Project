import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:diabetes_project/main.dart';

class FootReading {
  final DateTime timestamp;
  final double avgTemp;
  final double maxPressure;
  final int prediction;

  FootReading({
    required this.timestamp,
    required this.avgTemp,
    required this.maxPressure,
    required this.prediction,
  });
}

class HistoricalDataScreen extends StatefulWidget {
  const HistoricalDataScreen({Key? key}) : super(key: key);

  @override
  State<HistoricalDataScreen> createState() =>
      _HistoricalDataScreenState();
}

class _HistoricalDataScreenState
    extends State<HistoricalDataScreen> {
  List<FootReading> _readings = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  /// تحديث تلقائي عند دخول الشاشة
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final supabase = Supabase.instance.client;

    try {
      final response = await supabase
          .from('readings')
          .select()
          .order('created_at', ascending: true);

      if (response.isEmpty) return;

      setState(() {
        _readings = response.map<FootReading>((row) {
          final temps = [
            row['Temp1'],
            row['Temp2'],
            row['BigF_T'],
            row['Side_T'],
            row['Center_T']
          ].map((e) => (e ?? 36.5).toDouble()).toList();

          final pressures = [
            row['Pres1'],
            row['Pres2'],
            row['BigF_P'],
            row['Side_P'],
            row['Center_P']
          ].map((e) => (e ?? 0).toDouble()).toList();

          return FootReading(
            timestamp: DateTime.parse(row['created_at']),
            avgTemp:
                temps.reduce((a, b) => a + b) /
                    temps.length,
            maxPressure:
                pressures.reduce(
                    (a, b) => a > b ? a : b),
            prediction:
                row['ai_result']?['prediction']
                        ?['prediction'] ??
                    0,
          );
        }).toList();
      });
    } catch (e) {
      print("History load error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings =
        Provider.of<AppSettings>(context);

    final isArabic =
        settings.locale.languageCode == 'ar';

    final theme = Theme.of(context);

    final tempData =
        _readings.map((e) => e.avgTemp).toList();

    final pressureData =
        _readings.map((e) => e.maxPressure).toList();

    return Scaffold(
      backgroundColor:
          theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            /// HEADER
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14),
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        isArabic
                            ? 'سجل القياسات'
                            : 'Measurements History',
                        style: theme
                            .textTheme.titleLarge
                            ?.copyWith(
                                fontWeight:
                                    FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isArabic
                            ? 'ملخص اتجاهات القدم اليمنى'
                            : 'Right-foot trends summary',
                        style: theme
                            .textTheme.bodyMedium
                            ?.copyWith(
                                color:
                                    Colors.grey[700],
                                fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            /// SUMMARY CARDS
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(
                        horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _SmallStatCard(
                        title: isArabic
                            ? 'متوسط الحرارة'
                            : 'Avg Temperature',
                        value:
                            _readings.isNotEmpty
                                ? '${_readings.last.avgTemp.toStringAsFixed(1)} °C'
                                : '--',
                        subtitle: isArabic
                            ? 'آخر قراءة'
                            : 'Latest reading',
                        color:
                            Colors.redAccent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SmallStatCard(
                        title: isArabic
                            ? 'أقصى ضغط'
                            : 'Max Pressure',
                        value:
                            _readings.isNotEmpty
                                ? _readings.last.maxPressure
                                    .toStringAsFixed(
                                        0)
                                : '--',
                        subtitle: isArabic
                            ? 'آخر قراءة'
                            : 'Latest reading',
                        color:
                            Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(
                child: SizedBox(height: 12)),

            /// TEMP TREND
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(
                        horizontal: 16),
                child: _TrendCard(
                  title: isArabic
                      ? 'اتجاه الحرارة'
                      : 'Temperature Trend',
                  data: tempData,
                  color:
                      Colors.redAccent,
                ),
              ),
            ),

            const SliverToBoxAdapter(
                child: SizedBox(height: 12)),

            /// PRESSURE TREND
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(
                        horizontal: 16),
                child: _TrendCard(
                  title: isArabic
                      ? 'اتجاه الضغط'
                      : 'Pressure Trend',
                  data: pressureData,
                  color:
                      Colors.deepPurple,
                ),
              ),
            ),

            const SliverToBoxAdapter(
                child: SizedBox(height: 18)),

            /// HISTORY TITLE
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(
                        horizontal: 16),
                child: Text(
                  isArabic
                      ? "القياسات السابقة"
                      : "Previous Readings",
                  style: theme
                      .textTheme.titleMedium
                      ?.copyWith(
                          fontWeight:
                              FontWeight.bold),
                ),
              ),
            ),

            /// HISTORY LIST
            _readings.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding:
                          const EdgeInsets.all(
                              24),
                      child: Center(
                        child: Text(
                          isArabic
                              ? "لا توجد قراءات بعد"
                              : "No readings yet",
                        ),
                      ),
                    ),
                  )
                : SliverList(
                    delegate:
                        SliverChildBuilderDelegate(
                      (context, index) {
                        final reading =
                            _readings[
                                _readings.length -
                                    1 -
                                    index];

                        return Padding(
                          padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6),
                          child: Card(
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                      12),
                            ),
                            child: ListTile(
                              leading: const Icon(
                                  Icons.calendar_today),
                              title: Text(
                                "${reading.avgTemp.toStringAsFixed(1)} °C",
                              ),
                              subtitle: Text(
                                "${reading.maxPressure.toStringAsFixed(0)} pressure",
                              ),
                              trailing: Text(
                                "${reading.timestamp.day}/${reading.timestamp.month}/${reading.timestamp.year}",
                                style:
                                    const TextStyle(
                                        fontSize: 12),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount:
                          _readings.length,
                    ),
                  ),

            const SliverToBoxAdapter(
                child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}

/// SMALL STAT CARD
class _SmallStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _SmallStatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme
                  .textTheme.headlineMedium
                  ?.copyWith(
                      color: color,
                      fontWeight:
                          FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(subtitle),
          ],
        ),
      ),
    );
  }
}

/// TREND CARD
class _TrendCard extends StatelessWidget {
  final String title;
  final List<double> data;
  final Color color;

  const _TrendCard({
    required this.title,
    required this.data,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty)
      return const SizedBox();

    final spots = data
        .asMap()
        .entries
        .map((e) =>
            FlSpot(e.key.toDouble(), e.value))
        .toList();

    return Card(
      child: SizedBox(
        height: 150,
        child: LineChart(
          LineChartData(
            titlesData:
                const FlTitlesData(show: false),
            borderData:
                FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: color,
                dotData:
                    const FlDotData(show: false),
              )
            ],
          ),
        ),
      ),
    );
  }
}






