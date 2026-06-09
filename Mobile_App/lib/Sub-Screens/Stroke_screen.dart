import 'package:diabetes_project/Sub-Screens/stroke_result_screen.dart';
import 'package:diabetes_project/core/database/health_event.dart';
import 'package:diabetes_project/core/providers/health_history_provider.dart';
import 'package:diabetes_project/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StrokeScreen extends StatefulWidget {
  const StrokeScreen({super.key});

  @override
  State<StrokeScreen> createState() => _StrokeScreenState();
}

class _StrokeScreenState extends State<StrokeScreen> {

  final supabase = Supabase.instance.client;

  final _formKey = GlobalKey<FormState>();

  final _weight = TextEditingController();
  final _height = TextEditingController();

  double _calculatedBMI = 0;

  double _physicalHealth = 0;
  double _mentalHealth = 0;
  double _sleepHours = 7;

  String _gender = "Male";

  bool _smoking = false;
  bool _alcohol = false;
  bool _heartDisease = false;
  bool _diffWalking = false;
  bool _physicalActivity = false;
  bool _asthma = false;
  bool _kidneyDisease = false;
  bool _diabetic = false;
  String _ageCategory = "18-24";
  final String _genHealth = "Good";

  bool _loading = false;

  static const _texts = {
    'title': {'ar': 'تقييم السكتة الدماغية', 'en': 'Stroke Assessment'},
    'gender': {'ar': 'الجنس', 'en': 'Gender'},
    'male': {'ar': 'ذكر', 'en': 'Male'},
    'female': {'ar': 'أنثى', 'en': 'Female'},
    'weight': {'ar': 'الوزن (كجم)', 'en': 'Weight (kg)'},
    'height': {'ar': 'الطول (سم)', 'en': 'Height (cm)'},
    'bmi': {'ar': 'مؤشر كتلة الجسم:', 'en': 'BMI:'},
    'tiredness': {
      'ar': 'أيام الشعور بالتعب',
      'en': 'Days feeling tired'
    },
    'stress': {
      'ar': 'أيام الشعور بالتوتر',
      'en': 'Days feeling stressed'
    },
    'sleep': {'ar': 'ساعات النوم', 'en': 'Sleep Time'},
    'days': {'ar': 'أيام', 'en': 'days'},
    'hours': {'ar': 'ساعة', 'en': 'hours'},
    'smoking': {'ar': 'التدخين', 'en': 'Smoking'},
    'alcohol': {'ar': 'الكحول', 'en': 'Alcohol'},
    'heartDisease': {'ar': 'أمراض القلب', 'en': 'Heart Disease'},
    'diffWalking': {'ar': 'صعوبة المشي', 'en': 'Difficulty walking'},
    'workout': {'ar': 'التمرين', 'en': 'Workout'},
    'asthma': {'ar': 'الربو', 'en': 'Asthma'},
    'kidneyDisease': {'ar': 'أمراض الكلى', 'en': 'Kidney Disease'},
    'diabetic': {'ar': 'السكري', 'en': 'Diabetic'},
    'diabeticNo': {'ar': 'لا', 'en': 'No'},
    'diabeticYes': {'ar': 'نعم', 'en': 'Yes'},
    'diabeticBorderline': {
      'ar': 'سكري حدي',
      'en': 'Borderline Diabetes'
    },
    'ageCategory': {'ar': 'الفئة العمرية', 'en': 'Age Category'},
    'analyze': {'ar': 'تحليل', 'en': 'Analyze'},
    'required': {'ar': 'مطلوب', 'en': 'Required'},
    'error': {'ar': 'خطأ', 'en': 'Error'},
  };

  String _t(String key) {
    final isArabic =
        Provider.of<AppSettings>(
          context,
          listen: false,
        ).locale.languageCode == 'ar';

    return _texts[key]![isArabic ? 'ar' : 'en']!;
  }

  void _calculateBMI() {
    final weight = double.tryParse(_weight.text);
    final heightCm = double.tryParse(_height.text);

    if (weight != null && heightCm != null && heightCm > 0) {
      final heightM = heightCm / 100;

      setState(() {
        _calculatedBMI = weight / (heightM * heightM);
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _weight.addListener(_calculateBMI);
    _height.addListener(_calculateBMI);
  }


  double _mapAge(String value) {
    const map = {
      "18-24": 0,
      "25-29": 1,
      "30-34": 2,
      "35-39": 3,
      "40-44": 4,
      "45-49": 5,
      "50-54": 6,
      "55-59": 7,
      "60-64": 8,
      "65-69": 9,
      "70-74": 10,
      "75-79": 11,
      "80+": 12,
    };

    return map[value]!.toDouble();
  }

  double _mapGenHealth(String value) {
    const map = {
      "Excellent": 0,
      "Very good": 1,
      "Good": 2,
      "Fair": 3,
      "Poor": 4,
    };

    return map[value]!.toDouble();
  }

  Future<void> _submit() async {

    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final user = supabase.auth.currentUser;

    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    try {

      final data = {
        "email": user.email!,
        "Sex": _gender == "Male" ? 1 : 0,
        "BMI": _calculatedBMI,
        "Smoking": _smoking ? 1 : 0,
        "AlcoholDrinking": _alcohol ? 1 : 0,
        "HeartDisease": _heartDisease ? 1 : 0,
        "PhysicalHealth": _physicalHealth,
        "MentalHealth": _mentalHealth,
        "DiffWalking": _diffWalking ? 1 : 0,
        "Diabetic": _diabetic ? 1 : 0,
        "AgeCategory": _mapAge(_ageCategory),
        "PhysicalActivity": _physicalActivity ? 1 : 0,
        "GenHealth": _mapGenHealth(_genHealth),
        "SleepTime": _sleepHours,
        "Asthma": _asthma ? 1 : 0,
        "KidneyDisease": _kidneyDisease ? 1 : 0,
      };

      final insertedRow = await supabase
          .from("stroke")
          .insert(data)
          .select("id")
          .single();

      final insertedId = insertedRow["id"];

      Map<String, dynamic>? finalRow;

      for (int i = 0; i < 15; i++) {

        await Future.delayed(const Duration(seconds: 1));

        final row = await supabase
            .from("stroke")
            .select()
            .eq("id", insertedId)
            .maybeSingle();

        if (row != null && row["ai_result"] != null) {
          finalRow = row;
          break;
        }
      }

      setState(() => _loading = false);

      if (finalRow == null) return;

      final aiResult = finalRow["ai_result"];

      final strokeResult = aiResult["prediction"].toString() == "1"
          ? "High Risk"
          : "Low Risk";

      final score = strokeResult == "High Risk" ? 0.8 : 0.2;

      final level = strokeResult == "High Risk"
          ? RiskLevel.critical
          : RiskLevel.none;

      context.read<HealthHistoryProvider>().saveAndRefresh(
            HealthEvent(
              eventType: EventType.strokePrediction,
              riskScore: score,
              riskLevel: level,
              notes: strokeResult,
            ),
          );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StrokeResultScreen(
            result: strokeResult,
            generalHealth: _genHealth,
          ),
        ),
      );

    } catch (e) {

      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_t('error')}: $e'),
        ),
      );
    }
  }

  Widget _buildSlider(
    String title,
    double value,
    double max,
    Function(double) onChanged,
    String unit,
  ) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,

          children: [

            Expanded(
              child: Text(
                title,

                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            Text(
              "${value.toInt()} $unit",

              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        Slider(
          min: 0,
          max: max,
          divisions: max.toInt(),
          value: value,
          onChanged: onChanged,
        ),

        const SizedBox(height: 14),
      ],
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
  ) {

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),

      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,

        validator: (v) =>
            v == null || v.isEmpty
                ? _t('required')
                : null,

        decoration: InputDecoration(
          labelText: label,

          filled: true,
          fillColor: Theme.of(context).cardColor,

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitch(
    String title,
    bool value,
    Function(bool) onChanged,
  ) {

    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 10),

      child: Text(
        title,

        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,

        borderRadius: BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        children: children,
      ),
    );
  }

  @override
  void dispose() {
    _weight.dispose();
    _height.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final isArabic =
        Provider.of<AppSettings>(context).locale.languageCode == 'ar';

    final lang = isArabic ? 'ar' : 'en';

    return Scaffold(

      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,

        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [

            Container(
              padding: const EdgeInsets.all(8),

              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),

              child: Icon(
                Icons.health_and_safety_rounded,
                color: Colors.blue.shade700,
              ),
            ),

            const SizedBox(width: 10),

            Text(
              _texts['title']![lang]!,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Form(
          key: _formKey,

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              _buildSectionTitle(
                isArabic
                    ? "المعلومات الشخصية"
                    : "Personal Information",
              ),

              _buildCard(
                children: [

                  DropdownButtonFormField<String>(
                    value: _gender,

                    decoration: InputDecoration(
                      labelText: _texts['gender']![lang]!,

                      filled: true,
                      fillColor: Theme.of(context).cardColor,

                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                    ),

                    items: [
                      DropdownMenuItem(
                        value: "Male",
                        child:
                            Text(_texts['male']![lang]!),
                      ),

                      DropdownMenuItem(
                        value: "Female",
                        child:
                            Text(_texts['female']![lang]!),
                      ),
                    ],

                    onChanged: (v) =>
                        setState(() => _gender = v!),
                  ),

                  const SizedBox(height: 14),

                  _buildField(
                    _texts['weight']![lang]!,
                    _weight,
                  ),

                  _buildField(
                    _texts['height']![lang]!,
                    _height,
                  ),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),

                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(18),
                    ),

                    child: Text(
                      '${_texts['bmi']![lang]!} '
                      '${_calculatedBMI.toStringAsFixed(2)}',

                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              _buildSectionTitle(
                isArabic
                    ? "الحالة الصحية"
                    : "Health Status",
              ),

              _buildCard(
                children: [

                  _buildSlider(
                    _texts['tiredness']![lang]!,
                    _physicalHealth,
                    30,
                    (v) =>
                        setState(() => _physicalHealth = v),
                    _texts['days']![lang]!,
                  ),

                  _buildSlider(
                    _texts['stress']![lang]!,
                    _mentalHealth,
                    30,
                    (v) =>
                        setState(() => _mentalHealth = v),
                    _texts['days']![lang]!,
                  ),

                  _buildSlider(
                    _texts['sleep']![lang]!,
                    _sleepHours,
                    24,
                    (v) =>
                        setState(() => _sleepHours = v),
                    _texts['hours']![lang]!,
                  ),
                ],
              ),

              _buildSectionTitle(
                isArabic
                    ? "التاريخ المرضي"
                    : "Medical History",
              ),

              _buildCard(
                children: [

                  _buildSwitch(
                    _texts['smoking']![lang]!,
                    _smoking,
                    (v) => setState(() => _smoking = v),
                  ),

                  _buildSwitch(
                    _texts['alcohol']![lang]!,
                    _alcohol,
                    (v) => setState(() => _alcohol = v),
                  ),

                  _buildSwitch(
                    _texts['heartDisease']![lang]!,
                    _heartDisease,
                    (v) =>
                        setState(() => _heartDisease = v),
                  ),

                  _buildSwitch(
                    _texts['diffWalking']![lang]!,
                    _diffWalking,
                    (v) =>
                        setState(() => _diffWalking = v),
                  ),

                  _buildSwitch(
                    _texts['workout']![lang]!,
                    _physicalActivity,
                    (v) => setState(
                      () => _physicalActivity = v,
                    ),
                  ),

                  _buildSwitch(
                    _texts['asthma']![lang]!,
                    _asthma,
                    (v) => setState(() => _asthma = v),
                  ),

                  _buildSwitch(
                    _texts['kidneyDisease']![lang]!,
                    _kidneyDisease,
                    (v) =>
                        setState(() => _kidneyDisease = v),
                  ),
                ],
              ),

              _buildSectionTitle(
                isArabic
                    ? "بيانات إضافية"
                    : "Additional Information",
              ),

              _buildCard(
                children: [

                  _buildSwitch(
  _texts['diabetic']![lang]!,
  _diabetic,
  (v) => setState(() => _diabetic = v),
),

                  const SizedBox(height: 14),

                  DropdownButtonFormField<String>(
                    value: _ageCategory,

                    decoration: InputDecoration(
                      labelText:
                          _texts['ageCategory']![lang]!,

                      filled: true,
                      fillColor: Theme.of(context).cardColor,

                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                    ),

                    items: [
                      "18-24",
                      "25-29",
                      "30-34",
                      "35-39",
                      "40-44",
                      "45-49",
                      "50-54",
                      "55-59",
                      "60-64",
                      "65-69",
                      "70-74",
                      "75-79",
                      "80+",
                    ]
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(e),
                          ),
                        )
                        .toList(),

                    onChanged: (v) =>
                        setState(() => _ageCategory = v!),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 58,

                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xff2563EB),

                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(18),
                    ),
                  ),

                  onPressed:
                      _loading ? null : _submit,

                  icon: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,

                          child:
                              CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.analytics_outlined,
                          color: Colors.white,
                        ),

                  label: Text(
                    _loading
                        ? ""
                        : _texts['analyze']![lang]!,

                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}