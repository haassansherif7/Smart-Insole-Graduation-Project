import 'package:flutter/material.dart';
import 'package:diabetes_project/main.dart';
import 'package:provider/provider.dart'; 

class ArticleViewScreen extends StatelessWidget {
  final String title;
  final String content;
  final Color topicColor;

  const ArticleViewScreen({
    super.key,
    required this.title,
    required this.content,
    required this.topicColor,
  });

  final Map<String, String> _consultationNote = const {
    'ar': 'تذكر دائماً: استشر طبيبك قبل إجراء أي تغييرات جذرية على نظامك الغذائي أو ممارسة الرياضة.',
    'en': 'Always remember: Consult your doctor before making any drastic changes to your diet or exercise regimen.',
  };

  @override
  Widget build(BuildContext context) {
 final appSettings = Provider.of<AppSettings>(context);
    final isArabic = appSettings.locale.languageCode == 'ar';   
     final lang = isArabic ? 'ar' : 'en';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: topicColor, 
                  ),
            ),
            const SizedBox(height: 10),
            
            Container(
              width: 100,
              height: 4,
              color: topicColor,
            ),
            const SizedBox(height: 20),

            Text(
              content,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.8),
              textAlign: TextAlign.justify,
            ),

            const SizedBox(height: 30),

            Card(
              color: topicColor.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: topicColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _consultationNote[lang]!,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}