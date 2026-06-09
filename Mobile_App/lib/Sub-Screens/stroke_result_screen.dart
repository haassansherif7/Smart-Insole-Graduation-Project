import 'package:diabetes_project/MainScreens/chatbot.dart';
import 'package:flutter/material.dart';

class StrokeResultScreen extends StatelessWidget {
  final String result;
  final String generalHealth;

  const StrokeResultScreen({
    super.key,
    required this.result,
    required this.generalHealth,
  });

  @override
  Widget build(BuildContext context) {
    final bool isHighRisk = result == "High Risk";

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Assessment Result",
          style: TextStyle(
            color: Color(0xff5B6EF5),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Color(0xff5B6EF5),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),

            child: Column(
              children: [

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),

                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(24),
                  ),

                  child: Column(
                    children: [

                      Icon(
                        Icons.health_and_safety,
                        color: isHighRisk
                            ? Colors.red
                            : Colors.green,
                        size: 70,
                      ),

                      const SizedBox(height: 16),

                      Text(
                        isHighRisk
                            ? "Critical Risk"
                            : "Low Risk",
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: isHighRisk
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        "Predicted Disease: Stroke",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        isHighRisk
                            ? "Probability: 92%"
                            : "Probability: 15%",
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),

                      const SizedBox(height: 22),

                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),

                        child: LinearProgressIndicator(
                          value: isHighRisk ? 0.92 : 0.15,
                          minHeight: 10,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation(
                            isHighRisk
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                Align(
                  alignment: Alignment.centerLeft,

                  child: Text(
                    "Medical Recommendations",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                _buildAdviceCard(
                  context,
                  isHighRisk
                      ? "Seek medical help immediately."
                      : "Maintain a healthy lifestyle.",
                ),

                _buildAdviceCard(
                  context,
                  isHighRisk
                      ? "Monitor your condition daily."
                      : "Exercise regularly.",
                ),

                _buildAdviceCard(
                  context,
                  isHighRisk
                      ? "Strictly follow treatment plan."
                      : "Eat balanced meals.",
                ),

                _buildAdviceCard(
                  context,
                  isHighRisk
                      ? "Avoid physical strain."
                      : "Stay hydrated and sleep well.",
                ),

                _buildAdviceCard(
                  context,
                  isHighRisk
                      ? "Ensure continuous medical follow-up."
                      : "Keep monitoring your health.",
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),

                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      const Text(
                        "⚠️",
                        style: TextStyle(fontSize: 18),
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: Text(
                          "This analysis does not replace professional medical consultation.",
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 58,

                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff5B6EF5),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),

                    icon: const Icon(
                      Icons.smart_toy_outlined,
                      color: Colors.white,
                    ),

                    label: const Text(
                      "Ask AI Assistant",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatbotScreen(
                            strokeResult: result,
                            generalHealth: generalHealth,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdviceCard(BuildContext context, String text) {
    return Container(
      width: double.infinity,

      margin: const EdgeInsets.only(bottom: 14),

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,

        borderRadius: BorderRadius.circular(18),
      ),

      child: Row(
        children: [

          const Icon(
            Icons.medical_services_outlined,
            color: Colors.red,
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}