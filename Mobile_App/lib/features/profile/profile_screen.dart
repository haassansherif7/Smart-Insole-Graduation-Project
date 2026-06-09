import 'package:diabetes_project/Authentication/LoginScreen.dart';
import 'package:flutter/material.dart';
import 'package:diabetes_project/main.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _oldPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  String _userName = 'محمد علي';
  String _userEmail = 'user@example.com';
  String _joinDate = '18 مايو 2024';
  bool _loadingUserData = true;

  final Map<String, Map<String, String>> _texts = const {
    'profile_title': {'ar': 'الملف الشخصي', 'en': 'Profile'},
    'account_status': {'ar': 'حالة الحساب', 'en': 'Account Status'},
    'active': {'ar': 'نشط', 'en': 'Active'},
    'email': {'ar': 'البريد الإلكتروني', 'en': 'Email'},
    'name': {'ar': 'الاسم', 'en': 'Name'},
    'join_date': {'ar': 'تاريخ الانضمام', 'en': 'Join Date'},
    'settings': {'ar': 'الإعدادات', 'en': 'Settings'},
    'language': {'ar': 'اللغة', 'en': 'Language'},
    'english': {'ar': 'English', 'en': 'English'},
    'arabic': {'ar': 'العربية', 'en': 'Arabic'},
    'dark_mode': {'ar': 'الوضع الليلي', 'en': 'Dark Mode'},
    'change_password': {'ar': 'تغيير كلمة المرور', 'en': 'Change Password'},
    'old_password': {'ar': 'كلمة المرور القديمة', 'en': 'Old Password'},
    'new_password': {'ar': 'كلمة المرور الجديدة', 'en': 'New Password'},
    'confirm_password': {'ar': 'تأكيد كلمة المرور', 'en': 'Confirm Password'},
    'update_password': {'ar': 'تحديث كلمة المرور', 'en': 'Update Password'},
    'password_updated': {'ar': 'تم تحديث كلمة المرور بنجاح!', 'en': 'Password updated successfully!'},
    'logout': {'ar': 'تسجيل الخروج', 'en': 'Logout'},
    'confirm_logout': {'ar': 'هل أنت متأكد من تسجيل الخروج؟', 'en': 'Are you sure you want to logout?'},
    'yes': {'ar': 'نعم', 'en': 'Yes'},
    'cancel': {'ar': 'إلغاء', 'en': 'Cancel'},
    'required_field': {'ar': 'هذا الحقل مطلوب', 'en': 'This field is required'},
    'password_mismatch': {'ar': 'كلمات المرور غير متطابقة', 'en': 'Passwords do not match'},
  };

  @override
  void initState() {
    super.initState();
    _oldPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user != null) {
        _userEmail = user.email ?? 'user@example.com';

        // الحصول على الاسم من SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final firstName = prefs.getString('first_name') ?? 'محمد';
        final lastName = prefs.getString('last_name') ?? 'علي';
        _userName = '$firstName $lastName';

        // حساب تاريخ إنشاء الحساب
        if (user.createdAt.isNotEmpty) {
          final createdDate = DateTime.parse(user.createdAt);
          _joinDate =
              '${createdDate.day} ${_getMonthName(createdDate.month, false)} ${createdDate.year}';
        }
      }

      if (mounted) {
        setState(() => _loadingUserData = false);
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (mounted) {
        setState(() => _loadingUserData = false);
      }
    }
  }

  String _getMonthName(int month, bool isArabic) {
    const arabicMonths = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر'
    ];
    const englishMonths = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    final months = isArabic ? arabicMonths : englishMonths;
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = Provider.of<AppSettings>(context);
    final isArabic = appSettings.locale.languageCode == 'ar';
    final lang = isArabic ? 'ar' : 'en';
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_loadingUserData) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_texts['profile_title']![lang]!),
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_texts['profile_title']![lang]!),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // البيانات الشخصية
            _buildProfileHeader(lang, isDarkMode),
            const SizedBox(height: 30),

            // الإعدادات
            Text(
              _texts['settings']![lang]!,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            // تغيير اللغة
            _buildLanguageOption(appSettings, lang, isArabic),
            const SizedBox(height: 15),

            // الوضع الليلي
            _buildDarkModeToggle(appSettings, lang, isDarkMode),
            const SizedBox(height: 30),

            // تغيير كلمة المرور
            _buildChangePasswordSection(lang),
            const SizedBox(height: 30),

            // تسجيل الخروج
            _buildLogoutButton(lang),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(String lang, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1F2937) : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 40,
                child: Icon(Icons.person, size: 40),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _texts['name']![lang]!,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      _userName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.email, _texts['email']![lang]!, _userEmail, lang),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.calendar_today, _texts['join_date']![lang]!, _joinDate, lang),
          const SizedBox(height: 12),
          _buildStatusRow(_texts['account_status']![lang]!, _texts['active']![lang]!, lang),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, String lang) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(String label, String status, String lang) {
    return Row(
      children: [
        const Icon(Icons.verified, size: 18, color: Colors.green),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                status,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageOption(AppSettings appSettings, String lang, bool isArabic) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.language),
        title: Text(_texts['language']![lang]!),
        subtitle: Text(isArabic ? _texts['arabic']![lang]! : _texts['english']![lang]!),
        trailing: DropdownButton<String>(
          value: isArabic ? 'ar' : 'en',
          items: [
            DropdownMenuItem(
              value: 'ar',
              child: Text(_texts['arabic']![lang]!),
            ),
            DropdownMenuItem(
              value: 'en',
              child: Text(_texts['english']![lang]!),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              appSettings.setLocale(Locale(value));
            }
          },
        ),
      ),
    );
  }

  Widget _buildDarkModeToggle(AppSettings appSettings, String lang, bool isDarkMode) {
    return Card(
      child: ListTile(
        leading: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
        title: Text(_texts['dark_mode']![lang]!),
        trailing: Switch(
          value: isDarkMode,
          onChanged: (value) {
            appSettings.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
          },
        ),
      ),
    );
  }

 Widget _buildChangePasswordSection(String lang) { final isDark = Theme.of(context).brightness == Brightness.dark; return Container( width: double.infinity, padding: const EdgeInsets.all(18), decoration: BoxDecoration( color: isDark ? const Color(0xFF1F2937) : Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [ BoxShadow( color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4), ), ], ), child: ExpansionTile( textColor: isDark ? Colors.white : Colors.black87, collapsedTextColor: isDark ? Colors.white : Colors.black87, iconColor: isDark ? Colors.white : Colors.black87, collapsedIconColor: isDark ? Colors.white : Colors.black87, tilePadding: EdgeInsets.zero, leading: Container( padding: const EdgeInsets.all(10), decoration: BoxDecoration( color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14), ), child: Icon( Icons.lock_reset, color: Colors.blue.shade700, ), ), title: Text( _texts['change_password']![lang]!, style: TextStyle( fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87, ), ), children: [ const SizedBox(height: 10), _buildPasswordField( _oldPasswordController, _texts['old_password']![lang]!, Icons.lock_outline, ), const SizedBox(height: 14), _buildPasswordField( _newPasswordController, _texts['new_password']![lang]!, Icons.lock_outline, ), const SizedBox(height: 14), _buildPasswordField( _confirmPasswordController, _texts['confirm_password']![lang]!, Icons.lock_outline, ), const SizedBox(height: 20), SizedBox( width: double.infinity, height: 54, child: ElevatedButton.icon( onPressed: () => _updatePassword(lang), style: ElevatedButton.styleFrom( backgroundColor: const Color(0xff2563EB), shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(16), ), ), icon: const Icon( Icons.save_rounded, color: Colors.white, ), label: Text( _texts['update_password']![lang]!, style: const TextStyle( color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, ), ), ), ), ], ), ); }

 Widget _buildPasswordField(
  TextEditingController controller,
  String label,
  IconData icon,
) {

  return TextField(
    controller: controller,
    obscureText: true,

    decoration: InputDecoration(

      labelText: label,

      prefixIcon: Icon(
        icon,
        color: Colors.blue.shade700,
      ),

      filled: true,
      fillColor: Theme.of(context).cardColor,

      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),

        borderSide: BorderSide(
          color: Colors.blue.shade400,
          width: 1.5,
        ),
      ),
    ),
  );
}

  Widget _buildLogoutButton(String lang) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _showLogoutConfirmation(lang),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(
          _texts['logout']![lang]!,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }

  void _updatePassword(String lang) async {
    if (_oldPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_texts['required_field']![lang]!)),
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_texts['password_mismatch']![lang]!)),
      );
      return;
    }

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user?.email != null) {
        // التحقق من كلمة المرور القديمة بإعادة تسجيل الدخول
        await supabase.auth.signInWithPassword(
          email: user!.email!,
          password: _oldPasswordController.text,
        );

        // تحديث كلمة المرور مباشرة في Supabase
        await supabase.auth.updateUser(
          UserAttributes(password: _newPasswordController.text),
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(lang == 'ar'
                ? 'تم تحديث كلمة المرور بنجاح!'
                : 'Password updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        _oldPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      }
    } on AuthException  {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang == 'ar'
              ? 'خطأ: كلمة المرور القديمة غير صحيحة'
              : 'Error: Old password is incorrect'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang == 'ar'
              ? 'حدث خطأ: $e'
              : 'Error: $e'),
        ),
      );
    }
  }

  void _showLogoutConfirmation(String lang) {  
    showDialog( context: context, 
    builder: (dialogContext) => AlertDialog( title: Text(_texts['logout']![lang]!), 
    content: Text( _texts['confirm_logout']![lang]!, ), 
    actions: [ TextButton( onPressed: () => Navigator.pop(dialogContext),
    child: Text( _texts['cancel']![lang]!, ), ),
    TextButton( onPressed: () async { try { Navigator.pop(dialogContext); 
    await Supabase.instance.client.auth.signOut(); 
    if (!mounted) return; Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(
    builder: (_) => const LoginScreen(),
  ),
  (route) => false,
); 
    } catch (e) { 
      if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar( SnackBar( content: Text( lang == 'ar' ? 'خطأ في تسجيل الخروج' : 'Error logging out', )
      , )
      , 
      ); 
      } 
      },
       child: Text( _texts['yes']![lang]!, ),
        ),
         ],
          ),
           );
            }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}