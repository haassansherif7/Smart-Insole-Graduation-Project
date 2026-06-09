import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:diabetes_project/core/providers/health_history_provider.dart';
import 'package:diabetes_project/features/reports/pdf_report_service.dart';
import 'package:diabetes_project/main.dart';
import 'package:diabetes_project/core/widgets/chatbot_fab.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _service = PdfReportService();
  bool _generating = false;
  dynamic _rawError;

  Future<void> _share() async {
    await _generate((bytes) async {
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'diabetes_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    });
  }

  Future<void> _preview() async {
    await _generate((bytes) async {
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    });
  }

  Future<void> _generate(Future<void> Function(Uint8List bytes) action) async {
    setState(() {
      _generating = true;
      _rawError = null;
    });

    try {
      final provider = context.read<HealthHistoryProvider>();
      final events = provider.latest;
      final bytes = await _service.generateReport(events);
      await action(bytes);
    } catch (e) {
      setState(() => _rawError = e);
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<AppSettings>(context, listen: false).locale.languageCode == 'ar';

    final String? errorMessage = _rawError != null
        ? (isArabic
            ? 'تعذر إنشاء التقرير: $_rawError'
            : 'Failed to generate report: $_rawError')
        : null;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          leading: Builder(
            builder: (context) {
              final isArabic = Provider.of<AppSettings>(context, listen: false)
                  .locale.languageCode == 'ar';
              return IconButton(
                icon: Icon(
                  isArabic
                      ? Icons.arrow_forward_ios_rounded
                      : Icons.arrow_back_ios_rounded,
                ),
                onPressed: () => Navigator.pop(context),
              );
            },
          ),
          title: Text(isArabic ? 'التقرير الطبي' : 'Medical Report'),
          centerTitle: true,
        ),
        floatingActionButton: const ChatbotFAB(),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.picture_as_pdf,
                  size: 80, color: Color(0xFF4C6FFF)),
              const SizedBox(height: 16),
              Text(
                isArabic ? 'إنشاء التقرير الطبي' : 'Generate Medical Report',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                isArabic
                    ? 'سيتضمن التقرير ملخص جميع نتائج الفحوصات والتوصيات الطبية'
                    : 'The report will include a summary of all examination results and medical recommendations.',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 32),
              if (_generating)
                Center(
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 12),
                      Text(
                        isArabic
                            ? 'جاري إنشاء التقرير...'
                            : 'Generating report...',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              else ...[
                ElevatedButton.icon(
                  icon: const Icon(Icons.visibility_outlined),
                  label: Text(
                    isArabic ? 'معاينة التقرير' : 'Preview Report',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                  ),
                  onPressed: _preview,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.share_outlined),
                  label: Text(
                    isArabic ? 'مشاركة / تحميل' : 'Share / Download',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                  ),
                  onPressed: _share,
                ),
              ],
              if (errorMessage != null) ...[
                const SizedBox(height: 16),
                Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(errorMessage,
                        style: const TextStyle(color: Colors.red)),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Text(
                  isArabic
                      ? 'تنبيه: هذا التقرير مُنشأ بواسطة الذكاء الاصطناعي لأغراض المساعدة فقط ولا يُغني عن استشارة الطبيب المختص.'
                      : 'Notice: This report is generated by AI for assistance purposes only and does not replace consulting a specialist.',
                  style: const TextStyle(fontSize: 12, color: Colors.brown),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
