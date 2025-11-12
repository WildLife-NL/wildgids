import 'package:flutter/material.dart';
import 'package:wildrapport/constants/app_colors.dart';
import 'package:wildrapport/constants/app_text_theme.dart';
import 'package:wildrapport/widgets/shared_ui_widgets/white_bulk_button.dart';
// circle icon container no longer used here (buttons are text-only)

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
              style: AppTextTheme.textTheme.titleLarge?.copyWith(
                fontSize: finalFontSize,
                color: const Color.fromARGB(255, 0, 0, 0),
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
    // Icons and arrows removed per design — buttons should be text-only
    return WhiteBulkButton(
      text: text,
      leftWidget: null,
      // no right icon
      showIcon: false,
      showShadow: false,
      // make the buttons slimmer: height based on computed circleSize
      height: circleSize * 0.9,
      backgroundColor: AppColors.lightMintGreen,
      borderColor: AppColors.darkGreen,
      arrowColor: AppColors.darkGreen,
      textStyle: const TextStyle(color: Colors.black),
      onPressed: () => onStatusSelected(text),
    );
  }
}
