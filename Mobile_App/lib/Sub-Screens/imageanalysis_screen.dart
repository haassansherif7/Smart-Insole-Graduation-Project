/// =============================
/// IMPROVED CLEAN MEDICAL UI
/// نفس الألوان القديمة لكن بشكل احترافي
/// =============================

import 'dart:io';
import 'dart:convert';

import 'package:diabetes_project/MainScreens/chatbot.dart';
import 'package:diabetes_project/core/database/health_event.dart';
import 'package:diabetes_project/core/providers/health_history_provider.dart';
import 'package:diabetes_project/main.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class ImageAnalysisScreen extends StatefulWidget {
  const ImageAnalysisScreen({super.key});

  @override
  State<ImageAnalysisScreen> createState() => _ImageAnalysisScreenState();
}

class _ImageAnalysisScreenState extends State<ImageAnalysisScreen>
    with SingleTickerProviderStateMixin {
  File? _image;

  final ImagePicker _picker = ImagePicker();

  String _analysisResult = "";
  bool _isLoading = false;
  Color _resultColor = Colors.grey;
  String? _predictionResult;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final Map<String, Map<String, String>> _texts = const {
    "title": {
      "ar": "تحليل القدم السكري",
      "en": "Diabetic Foot Analysis"
    },
    "instruction": {
      "ar": "التقط صورة واضحة للمنطقة المصابة",
      "en": "Capture a clear image of the affected area"
    },
    "camera": {
      "ar": "الكاميرا",
      "en": "Camera"
    },
    "gallery": {
      "ar": "المعرض",
      "en": "Gallery"
    },
    "analyze": {
      "ar": "تحليل الصورة",
      "en": "Analyze Image"
    },
    "noImage": {
      "ar": "لم يتم اختيار صورة",
      "en": "No image selected"
    },
    "loading": {
      "ar": "جاري تحليل الصورة...",
      "en": "Analyzing image..."
    },
    "error": {
      "ar": "حدث خطأ في الاتصال بالسيرفر",
      "en": "Server connection error"
    },
  };

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color getGradeColor(String grade) {
    switch (grade) {
      case "Normal":
        return Colors.green;

      case "Grade 1":
        return Colors.lightGreen;

      case "Grade 2":
        return Colors.orange;

      case "Grade 3":
        return Colors.deepOrange;

      case "Grade4":
      case "Grade 4":
      case "Grade5":
      case "Grade 5":
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  IconData getGradeIcon(String grade) {
    switch (grade) {
      case "Normal":
        return Icons.check_circle;

      case "Grade 1":
      case "Grade 2":
        return Icons.warning_amber_rounded;

      default:
        return Icons.error;
    }
  }

  String getMedicalExplanation(String grade, bool isArabic) {
    final data = {
      "Normal": {
        "ar":
            "لا توجد قرحة قدم سكري ظاهرة حالياً.\nاستمر في الفحص اليومي للقدم.",
        "en":
            "No diabetic foot ulcer detected.\nContinue daily foot inspection."
      },

      "Grade 1": {
        "ar":
            "قرحة سطحية محدودة في الجلد.\nيُنصح بمتابعة الحالة طبياً.",
        "en":
            "Superficial ulcer detected.\nMedical follow-up is recommended."
      },

      "Grade 2": {
        "ar":
            "قرحة عميقة وصلت إلى الأوتار أو المفاصل.\nزيارة الطبيب ضرورية.",
        "en":
            "Deep ulcer reaching tendons or joints.\nMedical evaluation is required."
      },

      "Grade 3": {
        "ar":
            "قرحة مصحوبة بعدوى.\nيجب التدخل الطبي العاجل.",
        "en":
            "Ulcer with infection detected.\nImmediate medical care required."
      },

      "Grade 4": {
        "ar":
            "غرغرينا موضعية.\nالتوجه للمستشفى فوراً.",
        "en":
            "Localized gangrene detected.\nUrgent hospital visit required."
      },

      "Grade 5": {
        "ar":
            "غرغرينا شديدة.\nحالة طبية طارئة.",
        "en":
            "Extensive gangrene detected.\nEmergency medical intervention required."
      },
    };

    data["Grade1"] = data["Grade 1"]!;
    data["Grade2"] = data["Grade 2"]!;
    data["Grade3"] = data["Grade 3"]!;
    data["Grade4"] = data["Grade 4"]!;
    data["Grade5"] = data["Grade 5"]!;

    return data[grade]?[isArabic ? "ar" : "en"] ??
        (isArabic
            ? "تعذر تحديد الإصابة"
            : "Unable to determine condition");
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source);

    if (picked != null) {
      setState(() {
        _image = File(picked.path);
        _analysisResult = "";
        _predictionResult = null;
      });
    }
  }

  Future<void> _analyzeImage() async {
    final appSettings = Provider.of<AppSettings>(context, listen: false);

    final isArabic = appSettings.locale.languageCode == "ar";
    final lang = isArabic ? "ar" : "en";

    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_texts["noImage"]![lang]!),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _analysisResult = "";
    });

    try {
      var request = http.MultipartRequest(
        "POST",
        Uri.parse("https://web-production-7e9fe.up.railway.app/predict"),
      );

      request.files.add(
        await http.MultipartFile.fromPath("file", _image!.path),
      );

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();

        var jsonData = json.decode(responseData);

        String? prediction;

        for (final key in const [
          'prediction',
          'class',
          'result',
          'label',
          'grade',
          'predicted_class',
          'output'
        ]) {
          if (jsonData[key] is String) {
            prediction = jsonData[key] as String;
            break;
          }
        }

        prediction = prediction?.replaceAllMapped(
          RegExp(r'Grade(\d)'),
          (m) => 'Grade ${m[1]}',
        );

        if (prediction == null) {
          setState(() {
            _analysisResult = 'Invalid response';
            _isLoading = false;
          });
          return;
        }

        setState(() {
          _predictionResult = prediction;
          _analysisResult = getMedicalExplanation(
            prediction!,
            isArabic,
          );

          _resultColor = getGradeColor(prediction);
        });

        _animationController.forward(from: 0);

        if (mounted) {
          final score = _gradeToScore(prediction);
          final level = _scoreToRiskLevel(score);

          context.read<HealthHistoryProvider>().saveAndRefresh(
                HealthEvent(
                  eventType: EventType.imageAnalysis,
                  riskScore: score,
                  riskLevel: level,
                  notes: prediction,
                ),
              );
        }
      } else {
        setState(() {
          _analysisResult = _texts["error"]![lang]!;
        });
      }
    } catch (e) {
      setState(() {
        _analysisResult = _texts["error"]![lang]!;
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  double _gradeToScore(String grade) => switch (grade) {
        'Normal' => 0.05,
        'Grade 1' || 'Grade1' => 0.30,
        'Grade 2' || 'Grade2' => 0.50,
        'Grade 3' || 'Grade3' => 0.75,
        'Grade 4' || 'Grade4' => 0.90,
        'Grade 5' || 'Grade5' => 0.95,
        _ => 0.10,
      };

  RiskLevel _scoreToRiskLevel(double s) {
    if (s >= 0.8) return RiskLevel.critical;
    if (s >= 0.55) return RiskLevel.warning;
    if (s >= 0.25) return RiskLevel.info;

    return RiskLevel.none;
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = Provider.of<AppSettings>(context);

    final isArabic = appSettings.locale.languageCode == "ar";
    final lang = isArabic ? "ar" : "en";

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(
          _texts["title"]![lang]!,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            /// HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),

              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),

              child: Column(
                children: [

                  /// ICON SMALLER
                  Container(
                    padding: const EdgeInsets.all(12),

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),

                    child: Icon(
                      Icons.health_and_safety_outlined,
                      color: Theme.of(context).primaryColor,
                      size: 30,
                    ),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    _texts["instruction"]![lang]!,
                    textAlign: TextAlign.center,

                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// IMAGE AREA
            GestureDetector(
              onTap: () => _pickImage(ImageSource.gallery),

              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),

                height: 250,
                width: double.infinity,

                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.grey.shade100,

                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),

                child: _image != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(24),

                        child: Image.file(
                          _image!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [

                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 55,
                            color: Colors.grey.shade500,
                          ),

                          const SizedBox(height: 12),

                          Text(
                            _texts["noImage"]![lang]!,

                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 22),

            /// BUTTONS
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt_outlined),

                    label: Text(
                      _texts["camera"]![lang]!,
                    ),

                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        vertical: 15,
                      ),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),

                    onPressed: () =>
                        _pickImage(ImageSource.camera),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.photo_library_outlined),

                    label: Text(
                      _texts["gallery"]![lang]!,
                    ),

                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        vertical: 15,
                      ),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),

                    onPressed: () =>
                        _pickImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            /// ANALYZE BUTTON
            SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton(
                onPressed: _analyzeImage,

                style: ElevatedButton.styleFrom(
                  elevation: 2,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),

                child: Text(
                  _texts["analyze"]![lang]!,

                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            /// LOADING
            if (_isLoading)
              Column(
                children: [
                  const CircularProgressIndicator(),

                  const SizedBox(height: 14),

                  Text(
                    _texts["loading"]![lang]!,
                  ),
                ],
              ),

            /// RESULT
            if (_analysisResult.isNotEmpty)
              FadeTransition(
                opacity: _fadeAnimation,

                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),

                  decoration: BoxDecoration(
                    color: _resultColor.withOpacity(0.08),

                    borderRadius: BorderRadius.circular(22),

                    border: Border.all(
                      color: _resultColor.withOpacity(0.35),
                    ),
                  ),

                  child: Column(
                    children: [

                      Icon(
                        getGradeIcon(_predictionResult ?? ""),
                        color: _resultColor,
                        size: 38,
                      ),

                      const SizedBox(height: 10),

                      Text(
                        _predictionResult ?? "",

                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _resultColor,
                        ),
                      ),

                      const SizedBox(height: 16),

                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),

                        child: LinearProgressIndicator(
                          value: _gradeToScore(
                            _predictionResult ?? "",
                          ),

                          minHeight: 8,
                          color: _resultColor,
                          backgroundColor:
                              _resultColor.withOpacity(0.15),
                        ),
                      ),

                      const SizedBox(height: 18),

                      Text(
                        _analysisResult,

                        textAlign: TextAlign.center,

                        style: TextStyle(
                          fontSize: 15.5,
                          height: 1.6,
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            /// AI BUTTON
            if (_predictionResult != null) ...[
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 55,

                child: ElevatedButton.icon(
                  icon: const Icon(Icons.smart_toy_outlined),

                  label: Text(
                    isArabic
                        ? "اسأل المساعد الذكي"
                        : "Ask AI Assistant",
                  ),

                  style: ElevatedButton.styleFrom(
                    elevation: 1,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),

                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatbotScreen(
                        imageResult: _predictionResult,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}