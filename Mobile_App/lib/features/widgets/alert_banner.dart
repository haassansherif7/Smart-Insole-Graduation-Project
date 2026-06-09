import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:diabetes_project/core/alerts/alert_engine.dart';
import 'package:diabetes_project/core/providers/health_history_provider.dart';
import 'package:diabetes_project/main.dart';

class AlertBanner extends StatelessWidget {
  const AlertBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<AppSettings>(context).locale.languageCode == 'ar';
    final provider = context.watch<HealthHistoryProvider>();
    final alert = provider.currentAlert;

    if (alert == null || alert.level == AlertLevel.none || alert.level == AlertLevel.info) {
      return const SizedBox.shrink();
    }

    Color bgColor;
    Color borderColor;
    IconData icon;
    bool isDismissible;

    switch (alert.level) {
      case AlertLevel.critical:
        bgColor = Colors.red.shade50;
        borderColor = Colors.red;
        icon = Icons.emergency;
        isDismissible = false;
        break;
      case AlertLevel.warning:
        bgColor = Colors.orange.shade50;
        borderColor = Colors.orange;
        icon = Icons.warning_amber;
        isDismissible = true;
        break;
      case AlertLevel.info:
        bgColor = Colors.blue.shade50;
        borderColor = Colors.blue;
        icon = Icons.info_outline;
        isDismissible = true;
        break;
      case AlertLevel.none:
        return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: borderColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isArabic ? alert.arabicMessage : alert.arabicMessage,
              style: TextStyle(
                color: borderColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (isDismissible)
            IconButton(
              icon: Icon(Icons.close, size: 16, color: borderColor),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                // Dismiss by clearing last notif level temporarily
              },
            ),
        ],
      ),
    );
  }
}
