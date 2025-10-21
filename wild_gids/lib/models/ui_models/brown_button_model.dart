import 'dart:ui';

class BrownButtonModel {
  static const double defaultButtonHeight = 48.0;
  static const double defaultArrowIconSize = 24.0;
  static const double defaultRegularIconSize = 38.0;
  static const double defaultLeftIconPadding = 0.0;

  final String? text;
  final String? rightIconPath;
  final String? leftIconPath;
  final double rightIconSize;
  final double leftIconSize;
  final double height;
  final double? width;
  final double? fontSize;
  final double leftIconPadding;
  final Color? backgroundColor;

  BrownButtonModel({
    this.text,
    this.rightIconPath,
    this.leftIconPath,
    double? rightIconSize,
    double? leftIconSize,
    double? height,
    this.width,
    this.fontSize,
    double? leftIconPadding,
    this.backgroundColor,
  }) : rightIconSize =
           rightIconSize ??
           (rightIconPath?.contains('arrow') == true
               ? defaultArrowIconSize
               : defaultRegularIconSize),
       leftIconSize = leftIconSize ?? defaultRegularIconSize,
       height = height ?? defaultButtonHeight,
       leftIconPadding = leftIconPadding ?? defaultLeftIconPadding;

  Map<String, dynamic> toMap() => {
    'text': text,
    'rightIconPath': rightIconPath,
    'leftIconPath': leftIconPath,
    'rightIconSize': rightIconSize,
    'leftIconSize': leftIconSize,
    'height': height,
    'width': width,
    'fontSize': fontSize,
    'leftIconPadding': leftIconPadding,
    'backgroundColor': backgroundColor,
  };

  factory BrownButtonModel.fromMap(Map<String, dynamic> map) {
    return BrownButtonModel(
      text: map['text'],
      rightIconPath: map['rightIconPath'],
      leftIconPath: map['leftIconPath'],
      rightIconSize: map['rightIconSize'],
      leftIconSize: map['leftIconSize'],
      height: map['height'],
      width: map['width'],
      fontSize: map['fontSize'],
      leftIconPadding: map['leftIconPadding'],
      backgroundColor: map['backgroundColor'],
    );
  }

  @override
  String toString() =>
      'BrownButtonModel(text: $text, rightIconPath: $rightIconPath, leftIconPath: $leftIconPath)';
}
