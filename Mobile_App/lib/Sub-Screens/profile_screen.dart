import 'package:flutter/material.dart';
import 'package:diabetes_project/main.dart';
import 'package:provider/provider.dart'; 

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final Map<String, Map<String, String>> _defaultData = const {
    'name': {'ar': 'محمد علي', 'en': 'Mohamed Ali'},
    'diabetes_type': {'ar': 'النوع الثاني', 'en': 'Type Two'},
    'history': {'ar': 'قرحة سابقة في عام 2022', 'en': 'Previous ulcer in 2022'},
  };

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _diabetesTypeController;
  late TextEditingController _historyController;

  @override
  void initState() {
    super.initState();
final appSettings = Provider.of<AppSettings>(context);
    final isArabic = appSettings.locale.languageCode == 'ar'; 
        final lang = isArabic ? 'ar' : 'en';

    _nameController = TextEditingController(text: _defaultData['name']![lang]);
    _ageController = TextEditingController(text: '55');
    _diabetesTypeController = TextEditingController(text: _defaultData['diabetes_type']![lang]);
    _historyController = TextEditingController(text: _defaultData['history']![lang]);
  }

  final Map<String, Map<String, String>> _texts = const {
    'app_title': {'ar': 'تعديل الملف الشخصي', 'en': 'Edit Profile'},
    'name_label': {'ar': 'الاسم الكامل', 'en': 'Full Name'},
    'age_label': {'ar': 'العمر (سنة)', 'en': 'Age (Years)'},
    'diabetes_type_label': {'ar': 'نوع السكري', 'en': 'Diabetes Type'},
    'history_label': {'ar': 'السجل الطبي الهام', 'en': 'Key Medical History'},
    'save_button': {'ar': 'حفظ التعديلات', 'en': 'Save Changes'},
    'saved_success': {'ar': 'تم حفظ البيانات بنجاح!', 'en': 'Data saved successfully!'},
    'required_field': {'ar': 'هذا الحقل مطلوب', 'en': 'This field is required'},
  };

  void _saveProfile() {
final appSettings = Provider.of<AppSettings>(context);
    final isArabic = appSettings.locale.languageCode == 'ar'; 
        final lang = isArabic ? 'ar' : 'en';

    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_texts['saved_success']![lang]!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
final appSettings = Provider.of<AppSettings>(context);
    final isArabic = appSettings.locale.languageCode == 'ar'; 
        final lang = isArabic ? 'ar' : 'en';

    return Scaffold(
      appBar: AppBar(
        title: Text(_texts['app_title']![lang]!),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: CircleAvatar(
                  radius: 50,
                  child: Icon(Icons.person, size: 50),
                ),
              ),
              const SizedBox(height: 30),

              _buildInputField(
                _texts['name_label']![lang]!, 
                _nameController, 
                Icons.person_outline,
                _texts['required_field']![lang]!,
              ),
              const SizedBox(height: 15),

              _buildInputField(
                _texts['age_label']![lang]!, 
                _ageController, 
                Icons.cake_outlined, 
                _texts['required_field']![lang]!,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 15),

              _buildInputField(
                _texts['diabetes_type_label']![lang]!, 
                _diabetesTypeController, 
                Icons.local_hospital_outlined,
                _texts['required_field']![lang]!,
              ),
              const SizedBox(height: 15),

              _buildInputField(
                _texts['history_label']![lang]!, 
                _historyController, 
                Icons.history, 
                _texts['required_field']![lang]!,
                maxLines: 3,
              ),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _saveProfile,
                child: Text(_texts['save_button']![lang]!),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, IconData icon, String requiredMessage, {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return requiredMessage; 
        }
        return null;
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _diabetesTypeController.dispose();
    _historyController.dispose();
    super.dispose();
  }
}