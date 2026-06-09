import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:diabetes_project/core/database/health_event.dart';

class PdfReportService {
  Future<Uint8List> generateReport(
      Map<EventType, HealthEvent?> latestEvents) async {
    final fontData = await rootBundle
        .load('fonts/Cairo-VariableFont_slnt,wght.ttf');
    final cairoFont = pw.Font.ttf(fontData);

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: cairoFont, bold: cairoFont),
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => [
          _buildHeader(cairoFont),
          pw.SizedBox(height: 20),
          _buildRiskSummary(latestEvents, cairoFont),
          pw.SizedBox(height: 20),
          _buildRecommendations(latestEvents, cairoFont),
          pw.SizedBox(height: 20),
          _buildDisclaimer(cairoFont),
        ],
        footer: (ctx) => _buildFooter(ctx, cairoFont),
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(pw.Font font) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#4C6FFF'),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            'التقرير الطبي لمريض السكري',
            style: pw.TextStyle(
                font: font,
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'تاريخ التقرير: ${_formatDate(DateTime.now())}',
            style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.white),
            textDirection: pw.TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildRiskSummary(
      Map<EventType, HealthEvent?> events, pw.Font font) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('ملخص نتائج الفحوصات', font),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(1.5),
          },
          children: [
            _tableHeader(['نوع الفحص', 'درجة الخطر', 'المستوى'], font),
            for (final type in EventType.values)
              _tableRow(
                [
                  _typeName(type),
                  events[type] != null
                      ? '${(events[type]!.riskScore * 100).toStringAsFixed(0)}%'
                      : 'لا يوجد',
                  events[type] != null
                      ? _levelName(events[type]!.riskLevel)
                      : '-',
                ],
                font,
                _levelColor(events[type]?.riskLevel),
              ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildRecommendations(
      Map<EventType, HealthEvent?> events, pw.Font font) {
    final recs = _generateRecommendations(events);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('التوصيات الطبية', font),
        pw.SizedBox(height: 10),
        ...recs.map(
          (r) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('• ', style: pw.TextStyle(font: font, fontSize: 13)),
                pw.Expanded(
                  child: pw.Text(
                    r,
                    style: pw.TextStyle(font: font, fontSize: 13),
                    textDirection: pw.TextDirection.rtl,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildDisclaimer(pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#FFF9E6'),
        border: pw.Border(
          top: pw.BorderSide(color: PdfColor.fromHex('#F57F17'), width: 1),
          bottom: pw.BorderSide(color: PdfColor.fromHex('#F57F17'), width: 1),
        ),
      ),
      child: pw.Text(
        'تنبيه: هذا التقرير مُنشأ بواسطة نظام ذكاء اصطناعي لأغراض المساعدة فقط '
        'ولا يُغني عن استشارة الطبيب المختص. يُرجى مراجعة طبيبك لتفسير النتائج '
        'واتخاذ القرار الطبي المناسب.',
        style: pw.TextStyle(
            font: font, fontSize: 11, color: PdfColor.fromHex('#7A5000')),
        textDirection: pw.TextDirection.rtl,
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context ctx, pw.Font font) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'صفحة ${ctx.pageNumber} من ${ctx.pagesCount}',
          style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey),
          textDirection: pw.TextDirection.rtl,
        ),
        pw.Text(
          'نظام إدارة مرض السكري',
          style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey),
          textDirection: pw.TextDirection.rtl,
        ),
      ],
    );
  }

  pw.Widget _sectionTitle(String title, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#EEF1FF'),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
            font: font,
            fontSize: 15,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#4C6FFF')),
        textDirection: pw.TextDirection.rtl,
      ),
    );
  }

  pw.TableRow _tableHeader(List<String> cols, pw.Font font) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(color: PdfColor.fromHex('#4C6FFF')),
      children: cols
          .map((c) => pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  c,
                  style: pw.TextStyle(
                      font: font,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                      fontSize: 12),
                  textDirection: pw.TextDirection.rtl,
                ),
              ))
          .toList(),
    );
  }

  pw.TableRow _tableRow(
      List<String> cols, pw.Font font, PdfColor? highlightColor) {
    return pw.TableRow(
      children: cols
          .asMap()
          .entries
          .map((e) => pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  e.value,
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 12,
                    color: (e.key == 2 && highlightColor != null)
                        ? highlightColor
                        : PdfColors.black,
                  ),
                  textDirection: pw.TextDirection.rtl,
                ),
              ))
          .toList(),
    );
  }

  List<String> _generateRecommendations(Map<EventType, HealthEvent?> events) {
    final recs = <String>[];

    final sensor = events[EventType.sensorScan];
    if (sensor != null && sensor.riskScore > 0.5) {
      recs.add('مستويات الجلوكوز مرتفعة — راجع طبيبك لضبط الجرعة الدوائية.');
    }

    final image = events[EventType.imageAnalysis];
    if (image != null && image.riskScore > 0.4) {
      recs.add('هناك علامات على تغيرات في القدم — احرص على العناية اليومية بالقدمين وتجنب الإصابات.');
    }

    final stroke = events[EventType.strokePrediction];
    if (stroke != null && stroke.riskScore > 0.5) {
      recs.add('خطر السكتة الدماغية مرتفع — اتبع نظاماً غذائياً صحياً وراجع طبيب أعصاب.');
    }

    final general = events[EventType.generalHealth];
    if (general != null && general.riskScore > 0.4) {
      recs.add('المؤشرات الصحية العامة تستدعي الانتباه — احرص على الفحوصات الدورية.');
    }

    if (recs.isEmpty) {
      recs.add('نتائجك في المدى الآمن — استمر في اتباع الخطة الصحية الموصى بها.');
      recs.add('حافظ على نظام غذائي منخفض مؤشر الجلايسيمي وممارسة الرياضة بانتظام.');
    }

    recs.add('قياس سكر الدم يومياً وتسجيل النتائج لمتابعة التغيرات.');
    recs.add('شرب كميات كافية من الماء وتجنب المشروبات المحلاة.');

    return recs;
  }

  String _typeName(EventType type) => switch (type) {
        EventType.sensorScan => 'فحص الاستشعار',
        EventType.imageAnalysis => 'تحليل صورة القدم',
        EventType.strokePrediction => 'خطر السكتة الدماغية',
        EventType.generalHealth => 'الصحة العامة',
      };

  String _levelName(RiskLevel level) => switch (level) {
        RiskLevel.critical => 'حرج',
        RiskLevel.warning => 'تحذير',
        RiskLevel.info => 'تنبيه',
        RiskLevel.none => 'طبيعي',
      };

  PdfColor? _levelColor(RiskLevel? level) => switch (level) {
        RiskLevel.critical => PdfColor.fromHex('#D32F2F'),
        RiskLevel.warning => PdfColor.fromHex('#F57C00'),
        RiskLevel.info => PdfColor.fromHex('#1976D2'),
        RiskLevel.none => PdfColor.fromHex('#388E3C'),
        null => null,
      };

  String _formatDate(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year}';
}
