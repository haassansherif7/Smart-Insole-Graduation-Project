import 'package:diabetes_project/Authentication/LoginScreen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  final List<Map<String, String>> pages = [
    {
      "icon": "🦶",
      "title_ar": "متابعة صحة القدم",
      "desc_ar":
          "راقب حالة قدمك بشكل يومي واكتشف أي مشاكل مبكرًا قبل تطورها.",
      "title_en": "Foot Health Monitoring",
      "desc_en":
          "Monitor your foot health daily and detect problems early."
    },
    {
      "icon": "📊",
      "title_ar": "تحليل ذكي للبيانات",
      "desc_ar":
          "نظام ذكي يحلل قراءاتك الصحية ويعطيك مؤشرات واضحة عن حالتك.",
      "title_en": "Smart Data Analysis",
      "desc_en":
          "An intelligent system that analyzes your data and gives clear insights."
    },
    {
      "icon": "💡",
      "title_ar": "نصائح شخصية",
      "desc_ar":
          "احصل على نصائح مخصصة تساعدك في الحفاظ على صحتك اليومية.",
      "title_en": "Personalized Tips",
      "desc_en":
          "Get personalized tips to maintain your daily health."
    },
  ];

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Widget _buildPage({
    required String icon,
    required String title,
    required String desc,
    required bool isActive,
  }) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 600),
      opacity: isActive ? 1 : 0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 600),
        offset: isActive ? Offset.zero : const Offset(0, 0.15),
        curve: Curves.easeOut,
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 90)),
              const SizedBox(height: 40),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                desc,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isArabic =
        Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemBuilder: (context, index) {
                  return _buildPage(
                    icon: pages[index]["icon"]!,
                    title: isArabic
                        ? pages[index]["title_ar"]!
                        : pages[index]["title_en"]!,
                    desc: isArabic
                        ? pages[index]["desc_ar"]!
                        : pages[index]["desc_en"]!,
                    isActive: _currentIndex == index,
                  );
                },
              ),
            ),

            // Dots indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentIndex == index ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentIndex == index
                        ? const Color(0xFF4C6FFF)
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4C6FFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    if (_currentIndex == pages.length - 1) {
                      _finishOnboarding();
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Text(
                    _currentIndex == pages.length - 1
                        ? (isArabic ? "ابدأ الآن" : "Get Started")
                        : (isArabic ? "التالي" : "Next"),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
