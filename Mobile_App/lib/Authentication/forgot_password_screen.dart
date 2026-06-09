import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:diabetes_project/main.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    final isArabic =
        Provider.of<AppSettings>(context, listen: false).locale.languageCode ==
            'ar';

    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final redirectUrl = 'io.diabetes.app://reset-password';

      await Supabase.instance.client.auth.resetPasswordForEmail(
        _emailController.text.trim(),
        redirectTo: redirectUrl,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'تم إرسال رابط إعادة التعيين إلى بريدك الإلكتروني.'
                : 'Reset link sent to your email.',
          ),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.pop(context);

    } on AuthException catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic ? 'خطأ: ${err.message}' : 'Error: ${err.message}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic ? 'حدث خطأ: $e' : 'Error: $e',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _validateEmail(String? v, bool ar) {
    if (v == null || v.isEmpty) {
      return ar ? 'أدخل البريد الإلكتروني' : 'Enter email';
    }
    final reg = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!reg.hasMatch(v)) {
      return ar ? 'صيغة غير صحيحة' : 'Invalid email';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ar = Provider.of<AppSettings>(context).locale.languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(ar ? 'استعادة كلمة المرور' : 'Forgot Password'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: ar ? 'البريد الإلكتروني' : 'Email Address',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.email),
                  ),
                  validator: (v) => _validateEmail(v, ar),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _sendReset,
                    child: _loading
                        ? const CircularProgressIndicator()
                        : Text(ar ? 'إرسال الرابط' : 'Send Link'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}