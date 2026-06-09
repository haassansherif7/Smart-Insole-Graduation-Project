import 'package:diabetes_project/MainScreens/chatbot.dart';
import 'package:diabetes_project/MainScreens/daily_monitoring_screen.dart';
import 'package:diabetes_project/MainScreens/doctor_communication_screen.dart';
import 'package:diabetes_project/MainScreens/historical_data_screen.dart';
import 'package:diabetes_project/Sub-Screens/choice_screen.dart';
import 'package:flutter/material.dart';
import 'package:diabetes_project/main.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  String _temperature = '';
  String _pressure = 'normal';

  void updateSensorData(String temp, String pressure) {
    setState(() {
      _temperature = temp;
      _pressure = pressure;
    });
  }

  List<Widget> get _screens => [
    DailyMonitoringScreen(
      onSensorUpdate: updateSensorData,
    ),
    const HistoricalDataScreen(),
    DoctorCommunicationScreen(),
    ChatbotScreen(
      temperature: _temperature.isNotEmpty ? _temperature : null,
      pressure: _pressure != 'normal' ? _pressure : null,
      
    ),
  ];

  final List<Map<String, String>> _navItems = const [
    {'ar': 'الرئيسية', 'en': 'Dashboard'},
    {'ar': 'السجل', 'en': 'History'},
    {'ar': 'الطبيب', 'en': 'Doctor'},
    {'ar': 'المساعد', 'en': 'Assistant'},
  ];

  static const _icons = [
    Icons.dashboard_outlined,
    Icons.history_outlined,
    Icons.local_hospital_outlined,
    Icons.smart_toy_outlined,
  ];

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final appSettings = Provider.of<AppSettings>(context);
    final isArabic = appSettings.locale.languageCode == 'ar';
    final lang = isArabic ? 'ar' : 'en';
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        leading: IconButton(
          icon: Icon(
            isArabic
                ? Icons.arrow_forward_ios_rounded
                : Icons.arrow_back_ios_rounded,
          ),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ChoiceScreen()),
              );
            }
          },
        ),
        title: Text(
          _navItems[_selectedIndex][lang]!,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: theme.cardColor,
        currentIndex: _selectedIndex,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
        items: List.generate(
          _navItems.length,
          (i) => BottomNavigationBarItem(
            icon: Icon(_icons[i]),
            label: _navItems[i][lang]!,
          ),
        ),
      ),
    );
  }
}
