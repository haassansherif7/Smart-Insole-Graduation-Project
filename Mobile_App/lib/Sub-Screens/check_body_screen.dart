import 'package:diabetes_project/Sub-Screens/check_body_result_screen.dart.dart';
import 'package:diabetes_project/core/database/health_event.dart';
import 'package:diabetes_project/core/providers/health_history_provider.dart';
import 'package:diabetes_project/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CheckBodyScreen extends StatefulWidget {
  const CheckBodyScreen({super.key});

  @override
  State<CheckBodyScreen> createState() => _CheckBodyScreenState();
}

class _CheckBodyScreenState extends State<CheckBodyScreen> {

  final supabase = Supabase.instance.client;

  int _age = 25;
  double _glucose = 100;
  double _bloodPressure = 120;
  double _oxygen = 98;
  double _lengthOfStay = 3;
  double _cholesterol = 180;
  double _triglycerides = 150;
  double _hba1c = 5.5;
  double _sleepHours = 7;

  final _weight = TextEditingController();
  final _height = TextEditingController();

  double _calculatedBMI = 0;

  String _gender = "Male";

  bool _smoking = false;
  bool _alcohol = false;
  bool _familyHistory = false;

  double _activity = 3;
  double _dietScore = 5;
  double _stress = 5;

  bool _loading = false;

  static const _texts = {
    'title': {'ar': 'تقييم الصحة العامة', 'en': 'Health Assessment'},
    'age': {'ar': 'العمر', 'en': 'Age'},
    'gender': {'ar': 'الجنس', 'en': 'Gender'},
    'male': {'ar': 'ذكر', 'en': 'Male'},
    'female': {'ar': 'أنثى', 'en': 'Female'},
    'glucose': {'ar': 'الجلوكوز', 'en': 'Glucose'},
    'bloodPressure': {'ar': 'ضغط الدم', 'en': 'Blood Pressure'},
    'weight': {'ar': 'الوزن (كجم)', 'en': 'Weight (kg)'},
    'height': {'ar': 'الطول (سم)', 'en': 'Height (cm)'},
    'bmi': {'ar': 'مؤشر كتلة الجسم المحسوب:', 'en': 'Calculated BMI:'},
    'oxygen': {'ar': 'تشبع الأكسجين', 'en': 'Oxygen Saturation'},
    'hospitalStay': {'ar': 'مدة الإقامة بالمستشفى', 'en': 'Hospital stay (days)'},
    'cholesterol': {'ar': 'الكوليسترول', 'en': 'Cholesterol'},
    'triglycerides': {'ar': 'الدهون الثلاثية', 'en': 'Triglycerides'},
    'hba1c': {'ar': 'HbA1c (متوسط سكر الدم)', 'en': 'HbA1c (average blood glucose)'},
    'sleepHours': {'ar': 'ساعات النوم', 'en': 'Sleep Hours'},
    'smoking': {'ar': 'التدخين', 'en': 'Smoking'},
    'alcohol': {'ar': 'الكحول', 'en': 'Alcohol'},
    'familyHistory': {'ar': 'التاريخ العائلي', 'en': 'Family History'},
    'workout': {'ar': 'التمرين', 'en': 'Workout'},
    'diet': {'ar': 'جودة الغذاء', 'en': 'Diet quality'},
    'stressLevel': {'ar': 'مستوى التوتر', 'en': 'Stress Level'},
    'analyze': {'ar': 'تحليل', 'en': 'Analyze'},
    'days': {'ar': 'أيام', 'en': 'days'},
    'hours': {'ar': 'ساعة', 'en': 'hours'},
    'error': {'ar': 'خطأ', 'en': 'Error'},
  };

  String _t(String key) {
    final isArabic = Provider.of<AppSettings>(
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

  @override
  void dispose() {
    _weight.dispose();
    _height.dispose();

    super.dispose();
  }

  static double _norm(double val, double min, double max) =>
      (val.clamp(min, max) - min) / (max - min);
      double _calculateDietScore() {

  double score = 5;

  if (_glucose < 140) {
    score += 2;
  }

  if (_cholesterol < 200) {
    score += 1.5;
  }

  if (_triglycerides < 200) {
    score += 1;
  }

  if (_activity >= 5) {
    score += 1;
  }

  if (_stress > 7) {
    score -= 1.5;
  }

  return score.clamp(1, 10);
}

Future<void> _submit() async {

  if (_weight.text.trim().isEmpty ||
      _height.text.trim().isEmpty) {

    final isArabic =
        Provider.of<AppSettings>(
          context,
          listen: false,
        ).locale.languageCode == 'ar';

    ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(
        backgroundColor: Colors.red.shade700,

        content: Text(
          isArabic
              ? "من فضلك أدخل الوزن والطول"
              : "Please enter weight and height",
        ),
      ),
    );

    return;
  }

  setState(() => _loading = true);

  final user = supabase.auth.currentUser;

  if (user == null) {
    setState(() => _loading = false);
    return;
  }

  try {

    final weight = double.tryParse(_weight.text) ?? 70.0;
    final heightCm = double.tryParse(_height.text) ?? 170.0;

    final heightM = heightCm / 100;

    final bmi = weight / (heightM * heightM);

    /// IMPORTANT
    /// AI DATA ORDER IS NOT CHANGED

    _dietScore = _calculateDietScore();

    final data = {
      "email": user.email!,
      "Age": _age,
      "Gender": _gender == "Male" ? 1 : 0,
      "Glucose": _norm(_glucose, 50, 400),
      "Blood Pressure": _norm(_bloodPressure, 80, 200),
      "BMI": _norm(bmi, 10, 50),
      "Oxygen Saturation": _norm(_oxygen, 70, 100),
      "LengthOfStay": _lengthOfStay,
      "Cholesterol": _norm(_cholesterol, 100, 400),
      "Triglycerides": _triglycerides,
      "HbA1c": _norm(_hba1c, 3, 15),
      "Smoking": _smoking ? 1 : 0,
      "Alcohol": _alcohol ? 1 : 0,
      "Physical Activity": _activity,
      "Diet Score": _dietScore,
      "Family History": _familyHistory ? 1 : 0,
      "Stress Level": _stress,
      "Sleep Hours": _sleepHours,
    };

    final insertedRow = await supabase
        .from("patient_data")
        .insert(data)
        .select("id")
        .single();

    final insertedId = insertedRow["id"];

    Map<String, dynamic>? finalRow;

    for (int i = 0; i < 15; i++) {

      await Future.delayed(const Duration(seconds: 1));

      final row = await supabase
          .from("patient_data")
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

    final diseaseName =
        aiResult["disease_name"]?.toString() ?? "Unknown";

    final probability =
        (aiResult["probability"] as num?)?.toDouble() ?? 0;

    final riskPercent = probability * 100;

    final riskLevel = riskPercent <= 50
        ? "Low Risk"
        : riskPercent <= 75
            ? "Moderate Risk"
            : riskPercent <= 90
                ? "High Risk"
                : "Critical Risk";

    if (mounted) {

      Provider.of<PredictionState>(
        context,
        listen: false,
      ).update(
        generalHealth: diseaseName,
        probability: probability,
        riskLevel: riskLevel,
        diseaseName: diseaseName,
      );
    }

    if (!mounted) return;

    final rl = probability >= 0.8
        ? RiskLevel.critical
        : probability >= 0.55
            ? RiskLevel.warning
            : probability >= 0.25
                ? RiskLevel.info
                : RiskLevel.none;

    context.read<HealthHistoryProvider>().saveAndRefresh(
          HealthEvent(
            eventType: EventType.generalHealth,
            riskScore: probability,
            riskLevel: rl,
            notes: diseaseName,
          ),
        );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckBodyResultScreen(
          data: finalRow!,
          prediction: aiResult["prediction"] ?? 0,
          probability: probability,
          diseaseName: diseaseName,
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

                DropdownButtonFormField<int>(
                  value: _age,

                  decoration: InputDecoration(
                    labelText: _texts['age']![lang]!,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                  ),

                  items: List.generate(
                    83,
                    (i) => DropdownMenuItem(
                      value: i + 18,
                      child: Text("${i + 18}"),
                    ),
                  ),

                  onChanged: (v) => setState(() => _age = v!),
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _gender,

                  decoration: InputDecoration(
                    labelText: _texts['gender']![lang]!,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                  ),

                  items: [
                    DropdownMenuItem(
                      value: "Male",
                      child: Text(_texts['male']![lang]!),
                    ),

                    DropdownMenuItem(
                      value: "Female",
                      child: Text(_texts['female']![lang]!),
                    ),
                  ],

                  onChanged: (v) => setState(() => _gender = v!),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: _weight,
                  keyboardType: TextInputType.number,

                  decoration: InputDecoration(
                    labelText: "${_texts['weight']![lang]!} *",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: _height,
                  keyboardType: TextInputType.number,

                  decoration: InputDecoration(
                    labelText: "${_texts['height']![lang]!} *",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                  ),
                ),

                const SizedBox(height: 16),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),

                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),

                  child: Text(
                    "${_texts['bmi']![lang]!} "
                    "${_calculatedBMI.toStringAsFixed(2)}",

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
                  ? "العلامات الحيوية"
                  : "Vital Signs",
            ),

            _buildCard(
              children: [

                _SliderField(
                  title: _texts['glucose']![lang]!,
                  initialValue: _glucose,
                  min: 0,
                  max: 300,
                  unit: "mg/dL",
                  onChanged: (v) => _glucose = v,
                ),

                _SliderField(
                  title: _texts['bloodPressure']![lang]!,
                  initialValue: _bloodPressure,
                  min: 0,
                  max: 200,
                  unit: "mmHg",
                  onChanged: (v) => _bloodPressure = v,
                ),

                _SliderField(
                  title: _texts['oxygen']![lang]!,
                  initialValue: _oxygen,
                  min: 0,
                  max: 100,
                  unit: "%",
                  onChanged: (v) => _oxygen = v,
                ),

                _SliderField(
                  title: _texts['hba1c']![lang]!,
                  initialValue: _hba1c,
                  min: 0,
                  max: 15,
                  unit: "%",
                  onChanged: (v) => _hba1c = v,
                ),
              ],
            ),

            _buildSectionTitle(
              isArabic
                  ? "المؤشرات الصحية"
                  : "Health Metrics",
            ),

            _buildCard(
              children: [

                _SliderField(
                  title: _texts['hospitalStay']![lang]!,
                  initialValue: _lengthOfStay,
                  min: 0,
                  max: 30,
                  unit: _texts['days']![lang]!,
                  onChanged: (v) => _lengthOfStay = v,
                ),

                _SliderField(
                  title: _texts['cholesterol']![lang]!,
                  initialValue: _cholesterol,
                  min: 0,
                  max: 400,
                  unit: "mg/dL",
                  onChanged: (v) => _cholesterol = v,
                ),

                _SliderField(
                  title: _texts['triglycerides']![lang]!,
                  initialValue: _triglycerides,
                  min: 0,
                  max: 500,
                  unit: "mg/dL",
                  onChanged: (v) => _triglycerides = v,
                ),

                _SliderField(
                  title: _texts['sleepHours']![lang]!,
                  initialValue: _sleepHours,
                  min: 0,
                  max: 24,
                  unit: _texts['hours']![lang]!,
                  onChanged: (v) => _sleepHours = v,
                ),
              ],
            ),

            _buildSectionTitle(
              isArabic
                  ? "نمط الحياة"
                  : "Lifestyle",
            ),

            _buildCard(
              children: [

                SwitchListTile(
                  title: Text(_texts['smoking']![lang]!),
                  value: _smoking,
                  onChanged: (v) => setState(() => _smoking = v),
                ),

                SwitchListTile(
                  title: Text(_texts['alcohol']![lang]!),
                  value: _alcohol,
                  onChanged: (v) => setState(() => _alcohol = v),
                ),

                SwitchListTile(
                  title: Text(_texts['familyHistory']![lang]!),
                  value: _familyHistory,
                  onChanged: (v) => setState(() => _familyHistory = v),
                ),

                _SliderField(
                  title: _texts['workout']![lang]!,
                  initialValue: _activity,
                  min: 0,
                  max: 10,
                  unit: "",
                  onChanged: (v) => _activity = v,
                ),

                _SliderField(
                  title: _texts['stressLevel']![lang]!,
                  initialValue: _stress,
                  min: 0,
                  max: 10,
                  unit: "",
                  onChanged: (v) => _stress = v,
                ),
              ],
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 58,

              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff2563EB),

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),

                onPressed: _loading ? null : _submit,

                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
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
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
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
}

class _SliderField extends StatefulWidget {

  final String title;
  final double initialValue;
  final double min;
  final double max;
  final String unit;
  final ValueChanged<double> onChanged;

  const _SliderField({
    required this.title,
    required this.initialValue,
    required this.min,
    required this.max,
    required this.unit,
    required this.onChanged,
  });

  @override
  State<_SliderField> createState() => _SliderFieldState();
}

class _SliderFieldState extends State<_SliderField> {

  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {

    final divisions = (widget.max - widget.min).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,

          children: [

            Expanded(
              child: Text(
                widget.title,

                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            Text(
              "${_value.toStringAsFixed(1)} ${widget.unit}",

              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        Slider(
          value: _value,
          min: widget.min,
          max: widget.max,
          divisions: divisions > 0 ? divisions : null,

          onChanged: (v) {

            setState(() {
              _value = v;
            });

            widget.onChanged(v);
          },
        ),

        const SizedBox(height: 10),
      ],
    );
  }
}