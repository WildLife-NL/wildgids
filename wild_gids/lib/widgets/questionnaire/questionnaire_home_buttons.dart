import 'package:flutter/material.dart';
import 'package:wildrapport/widgets/questionnaire/questionnaire_white_button.dart';
import 'package:wildrapport/utils/responsive_utils.dart';

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
    final responsive = context.responsive;
    final buttonWidth = responsive.wp(80); // 80% of screen width
    final buttonSpacing = responsive.hp(2); // 2% of screen height

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: responsive.wp(5),
          vertical: responsive.hp(2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildButton(
              text: "Overslaan",
              height: responsive.hp(8), // Responsive height
              width: buttonWidth * 0.6, // 60% of the buttonWidth
              onPressed: onOverslaanPressed,
            ),
            SizedBox(height: buttonSpacing),
            _buildButton(
              text: "Bewaar voor later",
              height: responsive.hp(8),
              width: buttonWidth * 0.8, // 80% of the buttonWidth
              onPressed: onBewaarVoorLaterPressed,
            ),
            SizedBox(height: buttonSpacing),
            _buildButton(
              text: "Vragenlijst Openen",
              height: responsive.hp(9),
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
