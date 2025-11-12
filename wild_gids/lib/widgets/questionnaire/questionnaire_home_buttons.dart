import 'package:flutter/material.dart';
import 'package:wildrapport/widgets/questionnaire/questionnaire_white_button.dart';

class QuestionnaireHomeButtons extends StatelessWidget {
  final Function() onOverslaanPressed;
  final Function() onBewaarVoorLaterPressed;
  final VoidCallback onVragenlijnstOpenenPressed;

  const QuestionnaireHomeButtons({
    super.key,
    required this.onOverslaanPressed,
    required this.onBewaarVoorLaterPressed,
    required this.onVragenlijnstOpenenPressed,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final buttonWidth = screenSize.width * 0.8; // 80% of screen width
    final buttonSpacing = screenSize.height * 0.02; // 2% of screen height
    
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenSize.width * 0.05,
          vertical: screenSize.height * 0.02,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildButton(
              text: "Overslaan",
              height: screenSize.height * 0.08, // Responsive height
              width: buttonWidth * 0.6, // 60% of the buttonWidth
              onPressed: onOverslaanPressed,
            ),
            SizedBox(height: buttonSpacing),
            _buildButton(
              text: "Bewaar voor later",
              height: screenSize.height * 0.08,
              width: buttonWidth * 0.8, // 80% of the buttonWidth
              onPressed: onBewaarVoorLaterPressed,
            ),
            SizedBox(height: buttonSpacing),
            _buildButton(
              text: "Vragenlijst Openen",
              height: screenSize.height * 0.09,
              width: buttonWidth, // Full buttonWidth
              onPressed: onVragenlijnstOpenenPressed,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required double height,
    required double width,
    required Function() onPressed,
  }) {
    return QuestionnaireWhiteButton(
      text: text,
      height: height,
      width: width,
      onPressed: onPressed,
    );
  }
}



