import 'package:flutter/material.dart';
import 'package:wildrapport/constants/app_colors.dart';
import 'package:wildrapport/widgets/shared_ui_widgets/white_bulk_button.dart';
import 'package:wildrapport/widgets/shared_ui_widgets/circle_icon_container.dart';

class SelectionButtonGroup extends StatelessWidget {
  final Function(String) onStatusSelected;
  final String title;
  final List<({String text, IconData? icon, String? imagePath})> buttons;

  const SelectionButtonGroup({
    super.key,
    required this.onStatusSelected,
    required this.buttons,
    this.title = 'Title', // Default value
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    // Calculate responsive text size
    final double fontSize = screenSize.width * 0.06;
    final double minFontSize = 20.0;
    final double maxFontSize = 28.0;
    final double finalFontSize = fontSize.clamp(minFontSize, maxFontSize);

    // Calculate responsive icon sizes
    final double circleSize = screenSize.width * 0.15;
    final double minCircleSize = 64.0;
    final double maxCircleSize = 80.0;
    final double finalCircleSize = circleSize.clamp(
      minCircleSize,
      maxCircleSize,
    );

    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenSize.width * 0.05,
          vertical: screenSize.height * 0.02,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              title,
              style: TextStyle(
                color: AppColors.brown,
                fontSize: finalFontSize,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            ...buttons.reversed.map(
              (button) => _buildButton(
                text: button.text,
                icon: button.icon,
                imagePath: button.imagePath,
                circleSize: finalCircleSize,
                arrowSize: finalCircleSize * 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required String text,
    IconData? icon,
    String? imagePath,
    required double circleSize,
    required double arrowSize,
  }) {
    Widget? leftWidget;

    if (icon != null) {
      leftWidget =
          text == 'Andere'
              ? CircleIconContainer(
                size: circleSize,
                icon: icon,
                iconColor: AppColors.brown,
                backgroundColor: AppColors.offWhite,
                iconSize: circleSize * 0.5,
              )
              : Icon(icon, color: AppColors.brown, size: circleSize * 0.8);
    } else if (imagePath != null) {
      leftWidget = Image.asset(
        imagePath,
        width: circleSize * 1.2,
        height: circleSize * 1.2,
        fit: BoxFit.contain,
      );
    }

    return WhiteBulkButton(
      text: text,
      leftWidget: leftWidget,
      rightWidget: Icon(
        Icons.arrow_forward_ios,
        color: AppColors.brown,
        size: arrowSize * 1.4,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.25),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      onPressed: () => onStatusSelected(text),
    );
  }
}
