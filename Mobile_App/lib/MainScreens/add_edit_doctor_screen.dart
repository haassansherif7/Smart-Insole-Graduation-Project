import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:diabetes_project/main.dart';

class AddEditDoctorScreen extends StatefulWidget {
  const AddEditDoctorScreen({super.key});

  @override
  State<AddEditDoctorScreen> createState() => _AddEditDoctorScreenState();
}

class _AddEditDoctorScreenState extends State<AddEditDoctorScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadDoctor();
  }

  Future<void> _loadDoctor() async {
    final prefs = await SharedPreferences.getInstance();
    _nameController.text = prefs.getString('doctor_name') ?? '';
    _emailController.text = prefs.getString('doctor_email') ?? '';
    _phoneController.text = prefs.getString('doctor_phone') ?? '';
  }

  Future<void> _saveDoctor() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('doctor_name', _nameController.text.trim());
    await prefs.setString('doctor_email', _emailController.text.trim());
    await prefs.setString('doctor_phone', _phoneController.text.trim());

    setState(() => _loading = false);

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isArabic =
        Provider.of<AppSettings>(context).locale.languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'بيانات الطبيب' : 'Doctor Information'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isArabic
                    ? 'من فضلك أدخل بيانات طبيبك ليتم التواصل معه ومشاركة التقارير.'
                    : 'Please enter your doctor’s information to share reports.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 30),

              _buildField(
                controller: _nameController,
                icon: Icons.badge_outlined,
                label: isArabic ? 'اسم الطبيب' : 'Doctor Name',
                validator: (v) =>
                    v == null || v.isEmpty ? (isArabic ? 'مطلوب' : 'Required') : null,
              ),
              const SizedBox(height: 15),

              _buildField(
                controller: _emailController,
                icon: Icons.email_outlined,
                label: isArabic ? 'البريد الإلكتروني' : 'Email',
                keyboard: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return isArabic ? 'مطلوب' : 'Required';
                  }
                  if (!v.contains('@')) {
                    return isArabic ? 'بريد غير صالح' : 'Invalid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              _buildField(
                controller: _phoneController,
                icon: Icons.phone_outlined,
                label: isArabic ? 'رقم الهاتف (اختياري)' : 'Phone (optional)',
                keyboard: TextInputType.phone,
              ),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _loading ? null : _saveDoctor,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        isArabic ? 'حفظ البيانات' : 'Save Information',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
