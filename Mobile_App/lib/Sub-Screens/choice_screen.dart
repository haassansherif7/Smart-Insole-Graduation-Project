import 'package:diabetes_project/MainScreens/home_screen.dart';
import 'package:diabetes_project/Sub-Screens/Stroke_screen.dart';
import 'package:diabetes_project/Sub-Screens/check_body_screen.dart';
import 'package:diabetes_project/Sub-Screens/imageanalysis_screen.dart';
import 'package:diabetes_project/features/dashboard/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:diabetes_project/main.dart';
import 'package:diabetes_project/core/widgets/chatbot_fab.dart';
import 'package:diabetes_project/features/profile/profile_screen.dart';
import 'package:provider/provider.dart';

class ChoiceScreen extends StatefulWidget {
  const ChoiceScreen({super.key});

  @override
  State<ChoiceScreen> createState() => _ChoiceScreenState();
}

class _ChoiceScreenState extends State<ChoiceScreen> {
  String _firstName = '';

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _firstName = prefs.getString('first_name') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {

    final appSettings =
        Provider.of<AppSettings>(context);

    final isArabic =
        appSettings.locale.languageCode == 'ar';

    final theme = Theme.of(context);

    final accentColor =
        theme.colorScheme.secondary;

    

    return Scaffold(

      resizeToAvoidBottomInset: false,

      backgroundColor:
          theme.scaffoldBackgroundColor,

      floatingActionButton:
          const ChatbotFAB(),

      floatingActionButtonLocation:
          FloatingActionButtonLocation.endFloat,

      body: SafeArea(

        child: SingleChildScrollView(

          physics:
              const BouncingScrollPhysics(),

          padding: const EdgeInsets.fromLTRB(
            22,
            20,
            22,
            130,
          ),

          child: Column(

            crossAxisAlignment:
                CrossAxisAlignment.stretch,

            children: [

              /// TOP BAR
              Row(

                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,

                children: [

                  GestureDetector(

                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const ProfileScreen(),
                      ),
                    ),

                    child: CircleAvatar(

                      radius: 24,

                      backgroundColor:
                          const Color(0xFF00B4A6),

                      child: Text(

                        (Supabase
                                    .instance
                                    .client
                                    .auth
                                    .currentUser
                                    ?.email
                                    ?.substring(0, 1) ??
                                'U')
                            .toUpperCase(),

                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  /// LANGUAGE BUTTON
                  InkWell(

                    borderRadius:
                        BorderRadius.circular(20),

                    onTap: () {

                      appSettings.setLocale(
                        isArabic
                            ? const Locale('en')
                            : const Locale('ar'),
                      );
                    },

                    child: Container(

                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),

                      decoration: BoxDecoration(

                        borderRadius:
                            BorderRadius.circular(20),

                        border: Border.all(
                          color: accentColor
                              .withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),

                      child: Text(

                        isArabic
                            ? 'EN'
                            : 'عربي',

                        style: TextStyle(
                          color: accentColor,
                          fontWeight:
                              FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              /// WELCOME
              Text(

                _firstName.isNotEmpty
                    ? (isArabic ? 'مرحباً $_firstName 👋' : 'Hello $_firstName 👋')
                    : (isArabic ? 'مرحباً 👋' : 'Hello 👋'),

                style: theme
                    .textTheme.headlineSmall
                    ?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                ),
              ),

              const SizedBox(height: 8),

              Text(

                isArabic
                    ? 'كيف تشعر اليوم؟ اختر ما تريد متابعته.'
                    : 'How are you feeling today? Choose what you want to monitor.',

                style: theme.textTheme.bodyMedium
                    ?.copyWith(
                  height: 1.5,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 24),

              /// DASHBOARD BUTTON
              Container(

                padding: const EdgeInsets.all(18),

                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0),
                  borderRadius:
                      BorderRadius.circular(22),
                ),

                child: Row(

                  crossAxisAlignment:
                      CrossAxisAlignment.center,

                  children: [

                    const Icon(
                      Icons.dashboard_rounded,
                      color: Colors.white,
                      size: 28,
                    ),

                    const SizedBox(width: 14),

                    Expanded(

                      child: Column(

                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [

                          Text(

                            isArabic
                                ? 'لوحة التحكم'
                                : 'Dashboard',

                            maxLines: 1,

                            overflow:
                                TextOverflow.ellipsis,

                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(

                            isArabic
                                ? 'عرض ملخص حالتك الصحية'
                                : 'View your health summary',

                            maxLines: 2,

                            overflow:
                                TextOverflow.ellipsis,

                            style: TextStyle(
                              color: Colors.white
                                  .withValues(
                                alpha: 0.9,
                              ),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    IconButton(

                      onPressed: () {

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const DashboardScreen(),
                          ),
                        );
                      },

                      icon: Icon(
                        isArabic
                            ? Icons
                                .arrow_back_ios_new_rounded
                            : Icons
                                .arrow_forward_ios_rounded,

                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              /// SECTION TITLE
              Text(

                isArabic
                    ? 'الخدمات الصحية'
                    : 'Health Services',

                style: theme.textTheme.titleLarge
                    ?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 18),

              /// SMART FOOT
              _ChoiceCard(
                title: isArabic
                    ? 'المراقبة الذكية للقدم'
                    : 'Smart Foot Monitoring',

                description: isArabic
                    ? 'متابعة يومية لحالة القدم وتنظيم الرعاية الذاتية.'
                    : 'Daily monitoring and self-care tracking.',

                icon:
                    Icons.self_improvement_rounded,

                color: const Color(0xFF4C6FFF),

                isArabic: isArabic,

                onTap: () {

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const HomeScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 22),

              /// FOOT CAMERA
              _ChoiceCard(
                title: isArabic
                    ? 'تحليل القدم بالكاميرا'
                    : 'Foot Camera Scan',

                description: isArabic
                    ? 'التقاط صورة للقدم وتحليلها باستخدام الذكاء الاصطناعي.'
                    : 'Capture and analyze foot condition using AI.',

                icon:
                    Icons.camera_alt_rounded,

                color: const Color(0xFFFD8A5E),

                isArabic: isArabic,

                onTap: () {

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const ImageAnalysisScreen(),
                    ),
                  );
                  
                },
              ),

              const SizedBox(height: 22),

              /// STROKE CHECK
              _ChoiceCard(
                title: isArabic
                    ? 'فحص السكتة الدماغية'
                    : 'Stroke Check',

                description: isArabic
                    ? 'تحليل خطر الإصابة بالسكتة الدماغية باستخدام الذكاء الاصطناعي.'
                    : 'Analyze stroke risk using AI.',

                icon:
                    Icons.monitor_heart_rounded,

                color: const Color(0xFFE85D75),

                isArabic: isArabic,

                onTap: () {

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const StrokeScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 22),

              /// GENERAL CHECK
              _ChoiceCard(
                title: isArabic
                    ? 'فحص عام'
                    : 'General Check',

                description: isArabic
                    ? 'إجراء فحص شامل لحالتك الصحية.'
                    : 'Perform a full general health check.',

                icon:
                    Icons.health_and_safety_rounded,

                color: const Color(0xFF3FB98C),

                isArabic: isArabic,

                onTap: () {

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const CheckBodyScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isArabic;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    return InkWell(

      borderRadius:
          BorderRadius.circular(24),

      onTap: onTap,

      child: Ink(

        padding: const EdgeInsets.all(20),

        decoration: BoxDecoration(

          color: theme.cardColor,

          borderRadius:
              BorderRadius.circular(24),

          boxShadow: [

            BoxShadow(
              color:
                  Colors.black.withValues(
                alpha: 0.05,
              ),

              blurRadius: 14,

              offset: const Offset(0, 5),
            ),
          ],
        ),

        child: Row(

          crossAxisAlignment:
              CrossAxisAlignment.center,

          children: [

            Container(

              padding:
                  const EdgeInsets.all(14),

              decoration: BoxDecoration(
                color:
                    color.withValues(alpha: 0.12),

                borderRadius:
                    BorderRadius.circular(18),
              ),

              child: Icon(
                icon,
                size: 28,
                color: color,
              ),
            ),

            const SizedBox(width: 18),

            Expanded(

              child: Column(

                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  Text(

                    title,

                    maxLines: 1,

                    overflow:
                        TextOverflow.ellipsis,

                    style: theme.textTheme.bodyLarge
                        ?.copyWith(
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(

                    description,

                    maxLines: 2,

                    overflow:
                        TextOverflow.ellipsis,

                    style: theme.textTheme.bodySmall
                        ?.copyWith(
                      height: 1.4,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            Icon(
              isArabic
                  ? Icons.arrow_back_ios_new_rounded
                  : Icons.arrow_forward_ios_rounded,

              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}