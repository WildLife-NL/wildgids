import 'package:widgets/models/ui_models/brown_button_model.dart';

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
