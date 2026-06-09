import 'package:diabetes_project/MainScreens/chatbot.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:diabetes_project/main.dart';

class CheckBodyResultScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  final int prediction;
  final double probability;
  final String diseaseName;

  const CheckBodyResultScreen({
    super.key,
    required this.data,
    required this.prediction,
    required this.probability,
    required this.diseaseName,
  });

  @override
  Widget build(BuildContext context) {

    final isArabic =
        Provider.of<AppSettings>(context).locale.languageCode == 'ar';

    final double riskPercent = probability * 100;

    /// 📊 Risk Level Text
    String riskText;

    if (riskPercent <= 50) {
      riskText = isArabic ? "مخاطر منخفضة" : "Low Risk";
    } 
    else if (riskPercent <= 75) {
      riskText = isArabic ? "مخاطر متوسطة" : "Moderate Risk";
    } 
    else if (riskPercent <= 90) {
      riskText = isArabic ? "مخاطر مرتفعة" : "High Risk";
    } 
    else {
      riskText = isArabic ? "خطر حرج" : "Critical Risk";
    }

    /// 🎨 Dynamic Gradient Color
    Color riskColor = Color.lerp(
      Colors.green,
      Colors.red,
      probability,
    )!;

    /// 🩺 Medical Recommendations
    List<String> medicalTips;
    String medicalAdviceTitle;

    if (riskPercent <= 50) {

      medicalAdviceTitle =
          isArabic ? "إرشادات للحفاظ على صحتك" : "Health Maintenance Tips";

      medicalTips = isArabic
          ? [
              "استمر في اتباع نظام غذائي صحي.",
              "مارس النشاط البدني بانتظام.",
              "قم بالفحوصات الطبية الدورية.",
              "حافظ على مستوى ضغط الدم والسكر.",
              "احصل على نوم كافٍ يوميًا."
            ]
          : [
              "Maintain a balanced healthy diet.",
              "Exercise regularly.",
              "Do routine medical checkups.",
              "Monitor blood pressure and glucose.",
              "Ensure adequate daily sleep."
            ];
    }

    else if (riskPercent <= 75) {

      medicalAdviceTitle =
          isArabic ? "إرشادات للوقاية المبكرة" : "Early Prevention Advice";

      medicalTips = isArabic
          ? [
              "قلل من تناول السكريات.",
              "تابع مستوى السكر بانتظام.",
              "ابدأ برنامج نشاط بدني خفيف.",
              "تجنب التوتر الزائد.",
              "استشر طبيبك عند ظهور أعراض."
            ]
          : [
              "Reduce sugar intake.",
              "Monitor glucose levels regularly.",
              "Start light physical activity.",
              "Manage stress levels.",
              "Consult a doctor if symptoms appear."
            ];
    }

    else if (riskPercent <= 90) {

      medicalAdviceTitle =
          isArabic ? "إرشادات صحية هامة" : "Important Medical Advice";

      medicalTips = isArabic
          ? [
              "يرجى مراجعة الطبيب المختص.",
              "تابع قياس السكر يوميًا.",
              "اتبع نظام غذائي قليل الدهون.",
              "تجنب التدخين والكحول.",
              "التزم بأي علاج موصوف."
            ]
          : [
              "Please consult a specialist.",
              "Monitor glucose daily.",
              "Follow a low-fat diet.",
              "Avoid smoking and alcohol.",
              "Adhere to prescribed treatment."
            ];
    }

    else {

      medicalAdviceTitle =
          isArabic ? "تحذير طبي عاجل" : "Urgent Medical Attention";

      medicalTips = isArabic
          ? [
              "يرجى التوجه للطبيب فورًا.",
              "قم بمتابعة حالتك يوميًا.",
              "التزم بالعلاج الطبي.",
              "تجنب أي مجهود بدني زائد.",
              "احرص على المتابعة المستمرة."
            ]
          : [
              "Seek medical help immediately.",
              "Monitor your condition daily.",
              "Strictly follow treatment plan.",
              "Avoid physical strain.",
              "Ensure continuous medical follow-up."
            ];
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? "نتيجة التحليل" : "Assessment Result"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              color: riskColor.withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [

                    Icon(Icons.health_and_safety,
                        size: 65, color: riskColor),

                    const SizedBox(height: 15),

                    Text(
                      riskText,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: riskColor,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      isArabic
                          ? "التشخيص المتوقع: $diseaseName"
                          : "Predicted Disease: $diseaseName",
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 5),

                    Text(
                      isArabic
                          ? "نسبة الاحتمال: ${riskPercent.toStringAsFixed(1)}%"
                          : "Probability: ${riskPercent.toStringAsFixed(1)}%",
                      style: const TextStyle(fontSize: 14),
                    ),

                    const SizedBox(height: 15),

                    LinearProgressIndicator(
                      value: probability,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade300,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(riskColor),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                medicalAdviceTitle,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 12),

            ...medicalTips.map(
              (tip) => Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: ListTile(
                  leading: Icon(
                    Icons.medical_services_outlined,
                    color: riskColor,
                  ),
                  title: Text(tip),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              isArabic
                  ? "⚠️ هذا التحليل لا يغني عن استشارة الطبيب المختص."
                  : "⚠️ This analysis does not replace professional medical consultation.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatbotScreen(generalHealth: diseaseName),
                ),
              ),
              icon: const Icon(Icons.smart_toy_outlined),
              label: Text(isArabic ? "سؤال المساعد الذكي" : "Ask AI Assistant"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    vertical: 14, horizontal: 25),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: Text(isArabic ? "رجوع" : "Back"),
              style: ElevatedButton.styleFrom(
                backgroundColor: riskColor,
                padding: const EdgeInsets.symmetric(
                    vertical: 14, horizontal: 25),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}