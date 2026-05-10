import 'package:flutter/material.dart';
import 'package:wildgids/constants/app_colors.dart';
import 'package:wildgids/constants/app_text_theme.dart';
import 'package:wildgids/widgets/shared_ui_widgets/white_bulk_button.dart';
import 'package:wildgids/utils/responsive_utils.dart';
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
    final responsive = context.responsive;

    // Calculate responsive text size
    final double finalFontSize = responsive.fontSize(24);

    // Calculate responsive circle sizes
    final double finalCircleSize = responsive.sp(10);

    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: responsive.wp(5),
          vertical: responsive.hp(2),
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
    // Icons and arrows removed per design â€” buttons should be text-only
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

