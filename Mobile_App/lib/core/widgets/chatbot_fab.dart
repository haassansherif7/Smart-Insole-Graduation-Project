import 'package:flutter/material.dart';
import 'package:diabetes_project/MainScreens/chatbot.dart';

class ChatbotFAB extends StatelessWidget {
  const ChatbotFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'chatbot_fab',
      backgroundColor: const Color(0xFF00B4A6),
      shape: const CircleBorder(),
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ChatbotScreen()),
      ),
      child: const Icon(
        Icons.smart_toy_rounded,
        color: Colors.white,
        size: 28,
      ),
    );
  }
}
