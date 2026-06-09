import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:diabetes_project/Sub-Screens/choice_screen.dart';
import 'package:diabetes_project/main.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;

  Future<void> _register() async {
    final appSettings = Provider.of<AppSettings>(context, listen: false);
    final isArabic = appSettings.locale.languageCode == 'ar';

    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final supabase = Supabase.instance.client;

    try {
      final res = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        // data: {'username': 'optional_username'},
      );

      final session = res.session;

      if (session != null) {
        if (!mounted) return;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('first_name', _firstNameController.text.trim());
        await prefs.setString('last_name', _lastNameController.text.trim());

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ChoiceScreen()),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic
                  ? 'تم إنشاء الحساب وتسجيل الدخول'
                  : 'Account created & logged in',
            ),
          ),
        );
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic
                  ? 'تم إنشاء الحساب، تحقق من بريدك لتفعيل الحساب'
                  : 'Account created — please check your email to confirm.',
            ),
          ),
        );

        Navigator.pop(context);
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'فشل إنشاء الحساب: ${e.message}'
                : 'Signup failed: ${e.message}',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic ? 'حصل خطأ: $e' : 'Error: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    required Color primaryColor,
    required Color fillColor,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: primaryColor, width: 1.2),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = Provider.of<AppSettings>(context);
    final isArabic = appSettings.locale.languageCode == 'ar';

    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final accentColor = theme.colorScheme.secondary;

    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFF3F5FF),
                Color(0xFFE5ECFF),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Card(
                  elevation: 8,
                  shadowColor: Colors.black12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 22),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // زر تغيير اللغة في الجنب
                          Align(
                            alignment: isArabic
                                ? Alignment.centerLeft
                                : Alignment.centerRight,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                appSettings.setLocale(
                                  isArabic
                                      ? const Locale('en')
                                      : const Locale('ar'),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: accentColor.withValues(alpha: 0.7),
                                  ),
                                ),
                                child: Text(
                                  isArabic ? 'EN' : 'عربي',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: accentColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          Center(
                            child: Icon(
                              Icons.person_add_alt_1_rounded,
                              size: 52,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 10),

                          Text(
                            isArabic
                                ? 'إنشاء حساب جديد'
                                : 'Create New Account',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),

                          Text(
                            isArabic
                                ? 'الرجاء ملء البيانات التالية'
                                : 'Please fill in the following information',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[700],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 26),

                          // First Name
                          TextFormField(
                            controller: _firstNameController,
                            decoration: _inputDecoration(
                              label: isArabic ? 'الاسم الأول' : 'First Name',
                              icon: Icons.person_outline,
                              primaryColor: primaryColor,
                              fillColor: theme.cardColor,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return isArabic ? 'الرجاء إدخال الاسم الأول' : 'Please enter your first name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Last Name
                          TextFormField(
                            controller: _lastNameController,
                            decoration: _inputDecoration(
                              label: isArabic ? 'اسم العائلة' : 'Last Name',
                              icon: Icons.person_outline,
                              primaryColor: primaryColor,
                              fillColor: theme.cardColor,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return isArabic ? 'الرجاء إدخال اسم العائلة' : 'Please enter your last name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Email
                          TextFormField(
                            controller: _emailController,
                            decoration: _inputDecoration(
                              label: isArabic
                                  ? 'البريد الإلكتروني'
                                  : 'Email Address',
                              icon: Icons.email_outlined,
                              primaryColor: primaryColor,
                              fillColor: theme.cardColor,
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return isArabic
                                    ? 'الرجاء إدخال البريد الإلكتروني'
                                    : 'Please enter your email address';
                              }
                              final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]{2,}@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                              if (!emailRegex.hasMatch(value.trim())) {
                                return isArabic
                                    ? 'البريد الإلكتروني غير صحيح'
                                    : 'Invalid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Password
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: isArabic ? 'كلمة المرور' : 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              filled: true,
                              fillColor: theme.cardColor,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: primaryColor, width: 1.2)),
                            ),
                            obscureText: _obscurePassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return isArabic
                                    ? 'الرجاء إدخال كلمة المرور'
                                    : 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return isArabic
                                    ? 'يجب أن تكون كلمة المرور 6 أحرف على الأقل'
                                    : 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Register button
                          SizedBox(
                            height: 46,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _register,
                              child: _loading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation(Colors.white),
                                      ),
                                    )
                                  : Text(
                                      isArabic
                                          ? 'إنشاء الحساب'
                                          : 'Register',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          Center(
                            child: TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text(
                                isArabic
                                    ? 'لديك حساب بالفعل؟ تسجيل الدخول'
                                    : 'Already have an account? Login',
                                style: TextStyle(
                                  color: accentColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
