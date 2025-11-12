import 'package:wildrapport/models/ui_models/brown_button_model.dart';
import 'package:wildrapport/constants/app_colors.dart';

class ButtonModelFactory {
  static BrownButtonModel createLoginButton({
    required String text,
    String leftIconPath = '',
    String rightIconPath = '',
  }) {
    return BrownButtonModel(
      text: text,
      leftIconPath: leftIconPath,
      rightIconPath: rightIconPath,
      fontSize: 16,
      backgroundColor: AppColors.darkGreen,
      elevation: 0,
    );
  }

  static BrownButtonModel createStandardButton({
    required String text,
    String leftIconPath = '',
    String rightIconPath = '',
  }) {
    return BrownButtonModel(
      text: text,
      leftIconPath: leftIconPath,
      rightIconPath: rightIconPath,
    );
  }
}
