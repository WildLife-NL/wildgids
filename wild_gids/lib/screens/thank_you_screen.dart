// lib/screens/thank_you_screen.dart
import 'package:flutter/material.dart';
import '../widgets/deer_animation.dart';

class ThankYouScreen extends StatelessWidget {
  const ThankYouScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Full-screen animation
              const DeerAnimationPage(),

              // Text moved down
              Align(
                alignment: const Alignment(0, 0.6), // Moved down from center (0, 0) → (0, 0.3)
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    "Bedankt.\nRapport verzonden en succesvol afgerond.\nU kunt deze bekijken in uw profiel.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
