import 'package:diabetes_project/MainScreens/splash_screen.dart';
import 'package:diabetes_project/Sub-Screens/choice_screen.dart';
import 'package:diabetes_project/app_theme.dart';
import 'package:diabetes_project/core/providers/health_history_provider.dart';
import 'package:diabetes_project/core/providers/nutrition_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'Authentication/reset_password_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:diabetes_project/core/alerts/alert_notifier.dart';
import 'package:diabetes_project/core/background/background_service.dart';

class AppSettings extends ChangeNotifier {
  Locale _locale = const Locale('ar');
  ThemeMode _themeMode = ThemeMode.light;

  Locale get locale => _locale;
  ThemeMode get themeMode => _themeMode;

  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}

class PredictionState extends ChangeNotifier {
  String? generalHealth;
  double? probability;
  String? riskLevel;
  String? diseaseName;

  void update({
    required String generalHealth,
    required double probability,
    required String riskLevel,
    required String diseaseName,
  }) {
    this.generalHealth = generalHealth;
    this.probability = probability;
    this.riskLevel = riskLevel;
    this.diseaseName = diseaseName;
    notifyListeners();
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final FlutterLocalNotificationsPlugin notificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {

  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings settings =
      InitializationSettings(
    android: androidSettings,
  );

  await notificationsPlugin.initialize(settings);

  // Notification Channel
  const AndroidNotificationChannel channel =
      AndroidNotificationChannel(
    'danger_channel',
    'Danger Alerts',
    description: 'Alerts for dangerous foot temperature',
    importance: Importance.max,
  );

  await notificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Android 13+ permission
  await notificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();
}

class _AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    AlertNotifier.appInForeground = state == AppLifecycleState.resumed;
    debugPrint('=== App lifecycle: $state, foreground: ${AlertNotifier.appInForeground} ===');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsBinding.instance.addObserver(_AppLifecycleObserver());

  await initNotifications();
  await BackgroundService.initialize();
  await BackgroundService.startPeriodicTask();

  await Supabase.initialize(
    url: 'https://troryqhoyolczplgegmn.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRyb3J5cWhveW9sY3pwbGdlZ21uIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ4MDc0MjIsImV4cCI6MjA4MDM4MzQyMn0.jt5bt1bJkQTsKYnVWSH8x63qifE5qIX0WBR2N86ICd0',
  );

  /// Handle password recovery deep link
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    final event = data.event;

    if (event == AuthChangeEvent.passwordRecovery) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => const ResetPasswordScreen(),
        ),
      );
    }
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppSettings()),
        ChangeNotifierProvider(create: (_) => PredictionState()),
        ChangeNotifierProvider(create: (_) => HealthHistoryProvider()),
        ChangeNotifierProvider(create: (_) => NutritionProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AppSettings>(context);

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'تطبيق العناية بالقدم السكري',

      locale: settings.locale,
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,

      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          final session = Supabase.instance.client.auth.currentSession;
          if (session != null) return const ChoiceScreen();
          return const SplashScreen();
        },
      ),
    );
  }
}
