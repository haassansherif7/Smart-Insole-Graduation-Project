import 'package:diabetes_project/Sub-Screens/article_view_screen.dart';
import 'package:flutter/material.dart';
import 'package:diabetes_project/main.dart';
import 'package:provider/provider.dart'; 

class HealthEducationScreen extends StatelessWidget {
  const HealthEducationScreen({Key? key}) : super(key: key);

  final List<Map<String, dynamic>> _topics = const [
    {
      'title_ar': '1. إدارة النظام الغذائي',
      'title_en': '1. Diet Management',
      'icon': Icons.restaurant_menu_outlined,
      'color': Colors.green,
      
      'short_content_ar': 'تجنب السكريات المضافة والكربوهيدرات المكررة. ركز على الألياف (الخضروات والفواكه) والبروتينات الخالية من الدهون. استشر طبيب تغذية لوضع خطة وجبات مناسبة لمستويات السكر لديك.',
      'short_content_en': 'Avoid added sugars and refined carbohydrates. Focus on fiber (vegetables and fruits) and lean proteins. Consult a nutritionist to set a meal plan appropriate for your sugar levels.',
      
      'full_content_ar': 'التحكم في نسبة السكر يبدأ من المطبخ. يجب عليك التركيز على الأطعمة ذات المؤشر الجلايسيمي المنخفض مثل الحبوب الكاملة، الخضروات الورقية، والبقوليات. تجنب المشروبات الغازية والعصائر المحلاة. تقسيم الوجبات إلى 5 أو 6 وجبات صغيرة يساعد على استقرار مستويات السكر وتجنب الارتفاعات المفاجئة. شرب كمية كافية من الماء ضروري لترطيب الجسم ودعم وظائف الكلى.',
      'full_content_en': 'Blood sugar control starts in the kitchen. Focus on low-glycemic index foods like whole grains, leafy vegetables, and legumes. Avoid sodas and sweetened juices. Dividing meals into 5 or 6 small portions helps stabilize sugar levels and prevents sudden spikes. Drinking enough water is essential for hydration and kidney function support.',
    },
    {
      'title_ar': '2. أهمية النشاط البدني',
      'title_en': '2. Importance of Physical Activity',
      'icon': Icons.directions_run_outlined,
      'color': Colors.blueAccent,
      
      'short_content_ar': 'مارس الرياضة المعتدلة بانتظام (مثل المشي السريع) لمدة 30 دقيقة على الأقل 5 مرات أسبوعياً. تساعد الرياضة على تحسين حساسية الأنسولين وضبط مستويات السكر في الدم.',
      'short_content_en': 'Engage in moderate regular exercise (such as brisk walking) for at least 30 minutes, 5 times a week. Exercise helps improve insulin sensitivity and regulate blood sugar levels.',
      
      'full_content_ar': 'النشاط البدني لا يساعد فقط على حرق السعرات الحرارية، بل يحسن من استجابة الخلايا للأنسولين. ابدأ ببطء وتدريجياً. إذا كنت تعاني من اعتلال في الأعصاب، تجنب التمارين عالية الارتطام. المشي، السباحة، أو ركوب الدراجات هي خيارات ممتازة. تأكد من فحص قدميك قبل وبعد التمرين.',
      'full_content_en': 'Physical activity not only helps burn calories but also improves cell response to insulin. Start slowly and gradually. If you have nerve damage (neuropathy), avoid high-impact exercises. Walking, swimming, or cycling are excellent choices. Be sure to check your feet before and after exercise.',
    },
    {
      'title_ar': '3. الفحص اليومي للقدم',
      'title_en': '3. Daily Foot Examination',
      'icon': Icons.remove_red_eye_outlined,
      'color': Colors.redAccent,
      
      'short_content_ar': 'هذه خطوة حيوية: افحص قدميك يومياً بحثاً عن أي جروح، بثور، أو احمرار. العناية اليومية تقلل خطر حدوث قرح القدم السكرية.',
      'short_content_en': 'This is a vital step: Check your feet daily for any cuts, blisters, or redness. Daily care reduces the risk of diabetic foot ulcers.',
      
      'full_content_ar': 'يجب أن يكون فحص القدمين طقساً يومياً، خاصة بعد الاستيقاظ وقبل النوم. ابحث عن أي شقوق، تقرحات، أو تغيير في اللون. إذا كانت رؤية باطن القدم صعبة، استخدم مرآة. لا تقم أبداً بقص الأظافر بعمق، وتجنب استخدام أدوات حادة لإزالة مسامير القدم. تأكد من إبلاغ طبيبك فوراً عند ملاحظة أي علامة غير طبيعية.',
      'full_content_en': 'Foot inspection should be a daily ritual, especially after waking up and before sleeping. Look for any cracks, ulcers, or changes in color. If checking the sole of your foot is difficult, use a mirror. Never cut toenails too deeply, and avoid using sharp tools to remove calluses. Be sure to notify your doctor immediately upon noticing any unusual sign.',
    },
    {
      'title_ar': '4. متابعة قراءات السكر والضغط',
      'title_en': '4. Monitoring Blood Sugar and Pressure',
      'icon': Icons.monitor_heart_outlined,
      'color': Colors.purple,
      
      'short_content_ar': 'سجل قراءات السكر والضغط في أوقات منتظمة. هذا يساعدك ويساعد طبيبك على فهم كيفية استجابة جسمك للعلاج وتجنب المضاعفات الخطيرة.',
      'short_content_en': 'Record your sugar and blood pressure readings at regular times. This helps you and your doctor understand how your body responds to treatment and avoid serious complications.',
      
      'full_content_ar': 'المتابعة المنتظمة هي مفتاح التحكم في السكري. سجل القراءات في دفتر أو باستخدام تطبيقك لتسهيل عملية المراجعة مع الطبيب. ارتفاع أو انخفاض مستويات السكر بشكل متكرر يتطلب تعديلاً فورياً في خطة العلاج. لا تتهاون في قياس ضغط الدم أيضاً، فالسكري وضغط الدم يسيران جنباً إلى جنب.',
      'full_content_en': 'Regular monitoring is key to diabetes control. Record readings in a notebook or using your app to facilitate the review process with your doctor. Frequently high or low sugar levels require an immediate adjustment to the treatment plan. Do not neglect measuring blood pressure either, as diabetes and blood pressure go hand in hand.',
    },
  ];

  @override
  Widget build(BuildContext context) {
   final appSettings = Provider.of<AppSettings>(context);
    final isArabic = appSettings.locale.languageCode == 'ar';
    final String titleKey = isArabic ? 'title_ar' : 'title_en';
    final String shortContentKey = isArabic ? 'short_content_ar' : 'short_content_en';
    final String fullContentKey = isArabic ? 'full_content_ar' : 'full_content_en';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'التثقيف والرعاية الصحية الشاملة' : 'Comprehensive Health Education & Care',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            isArabic 
                ? 'دليل شامل لمرضى السكري للتحكم في الحالة والوقاية من المضاعفات.'
                : 'A comprehensive guide for diabetics to manage their condition and prevent complications.',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          
          ..._topics.map((topic) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 15.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: InkWell( 
                  borderRadius: BorderRadius.circular(15),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ArticleViewScreen(
                          title: topic[titleKey] as String,
                          content: topic[fullContentKey] as String, 
                          topicColor: topic['color'] as Color,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(topic['icon'] as IconData, color: topic['color'] as Color, size: 30),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                topic[titleKey] as String, 
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Text(
                          topic[shortContentKey] as String, 
                          style: Theme.of(context).textTheme.bodyLarge,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: isArabic ? Alignment.centerLeft : Alignment.centerRight,
                          child: Text(
                            isArabic ? 'اقرأ المزيد...' : 'Read More...', 
                            style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}