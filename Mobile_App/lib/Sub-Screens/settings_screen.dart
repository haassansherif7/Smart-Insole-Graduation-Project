import 'package:diabetes_project/Authentication/forgot_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart'; 
import '../Authentication/LoginScreen.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appSettings = Provider.of<AppSettings>(context);
    final isArabic = appSettings.locale.languageCode == 'ar';

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isArabic ? 'الإعدادات' : 'Settings'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [

            Text(
              isArabic ? 'الحساب' : 'Account',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(
                        isArabic ? 'تعديل الملف الشخصي' : 'Edit Profile'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ProfileScreen()),
                      );
                    },
                  ),
                  const Divider(height: 0),
                  ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: Text(
                        isArabic ? 'تغيير كلمة المرور' : 'Change Password'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const ForgotPasswordScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // قسم الإعدادات العامة
            Text(
              isArabic ? 'عام' : 'General',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                
                  // تغيير اللغة
                  ListTile(
                    leading: const Icon(Icons.language_outlined),
                    title: Text(isArabic ? 'تغيير اللغة' : 'Change Language'),
                    subtitle: Text(
                      appSettings.locale.languageCode == 'ar'
                          ? 'العربية'
                          : 'English',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _showLanguageDialog(context, appSettings),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // زر تسجيل الخروج
            ElevatedButton(
              onPressed: () async {
                // لو بتستخدم Supabase Auth تقدر تضيف:
                // await AuthService.logout();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(isArabic ? 'تسجيل الخروج' : 'Logout'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, AppSettings appSettings) {
    final isArabic = appSettings.locale.languageCode == 'ar';

    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            title: Text(isArabic ? 'اختر اللغة' : 'Select Language'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: const Text('العربية'),
                  value: 'ar',
                  groupValue: appSettings.locale.languageCode,
                  onChanged: (value) {
                    appSettings.setLocale(const Locale('ar'));
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<String>(
                  title: const Text('English'),
                  value: 'en',
                  groupValue: appSettings.locale.languageCode,
                  onChanged: (value) {
                    appSettings.setLocale(const Locale('en'));
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
