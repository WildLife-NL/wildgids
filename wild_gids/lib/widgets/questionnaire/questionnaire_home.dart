import 'package:flutter/material.dart';
import 'package:wildrapport/constants/app_text_theme.dart';
import 'package:wildrapport/screens/shared/overzicht_screen.dart';
import 'package:wildrapport/widgets/questionnaire/questionnaire_home_buttons.dart';

class QuestionnaireHome extends StatelessWidget {
  final VoidCallback nextScreen;
  final int amountOfQuestions;

  const QuestionnaireHome({super.key, required this.nextScreen, required this.amountOfQuestions});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final verticalSpacing = screenSize.height * 0.05; // 5% of screen height
    
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenSize.width * 0.08, // 8% of screen width
            vertical: screenSize.height * 0.08, // 8% of screen height
          ),
          child: Text(
            "Wil je de natuur helpen door een paar vragen te beantwoorden?",
            textAlign: TextAlign.center,
            style: AppTextTheme.textTheme.titleLarge?.copyWith(
              fontSize: screenSize.width * 0.055, // Responsive font size
              color: Colors.black,
              fontFamily: 'Roboto',
            ),
          ),
        ),
        Column(
          children: [
            Text(
              "Totaal",
              style: TextStyle(
                color: Colors.black,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.bold,
                fontSize: screenSize.width * 0.07, // Responsive font size
              ),
            ),
            Text(
              "$amountOfQuestions",
              style: TextStyle(
                color: Colors.black,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.bold,
                fontSize: screenSize.width * 0.07, // Responsive font size
              ),
            ),
          ],
        ),
        SizedBox(height: verticalSpacing),
        QuestionnaireHomeButtons(
          onOverslaanPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const OverzichtScreen()),
            );
          },
          onBewaarVoorLaterPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const OverzichtScreen()),
            );
          },
          onVragenlijnstOpenenPressed: () => nextScreen(),
        ),
      ],
    );
  }
}

