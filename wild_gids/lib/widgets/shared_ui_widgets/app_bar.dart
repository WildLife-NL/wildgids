import 'package:flutter/material.dart';
import 'package:wildrapport/constants/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:wildrapport/providers/app_state_provider.dart';

class CustomAppBar extends StatelessWidget {
  final IconData? leftIcon;
  final String? centerText;
  final IconData? rightIcon;
  final VoidCallback? onLeftIconPressed;
  final VoidCallback? onRightIconPressed;
  final bool preserveState;

  const CustomAppBar({
    super.key,
    this.leftIcon,
    this.centerText,
    this.rightIcon,
    this.onLeftIconPressed,
    this.onRightIconPressed,
    this.preserveState = true,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final appStateProvider = context.watch<AppStateProvider>();

    // Use the report type's display text if available, otherwise use provided centerText
    final displayText =
        appStateProvider.currentReportType?.displayText ?? centerText ?? '';

    // Calculate responsive dimensions
    final double barHeight = screenSize.height * 0.05; // 5% of screen height
    final double minHeight = 24.0;
    final double maxHeight = 40.0;
    final double finalHeight = barHeight.clamp(minHeight, maxHeight);

    // Calculate responsive text size
    final double fontSize = screenSize.width * 0.05; // 5% of screen width
    final double minFontSize = 16.0;
    final double maxFontSize = 24.0;
    final double finalFontSize = fontSize.clamp(minFontSize, maxFontSize);

    // Calculate responsive icon size
    final double iconSize = screenSize.width * 0.06; // 6% of screen width
    final double minIconSize = 24.0;
    final double maxIconSize = 32.0;
    final double finalIconSize = iconSize.clamp(minIconSize, maxIconSize);

    return Container(
      height: finalHeight,
      color: Colors.transparent,
      child: Row(
        children: [
          // Left section (1/4 of space)
          Expanded(
            flex: 1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leftIcon != null)
                  Padding(
                    padding: EdgeInsets.only(
                      left: screenSize.width * 0.04, // 4% of screen width
                    ),
                    child: GestureDetector(
                      onTap:
                          onLeftIconPressed ??
                          () {
                            Navigator.of(context).pop();
                          },
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: AppColors.brown,
                        size: finalIconSize,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Center text (2/4 of space)
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                displayText,
                style: TextStyle(
                  color: AppColors.brown,
                  fontSize: finalFontSize,
                  fontFamily: 'Arimo',
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Right section (1/4 of space)
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (rightIcon != null)
                  Padding(
                    padding: EdgeInsets.only(
                      right: screenSize.width * 0.04, // 4% of screen width
                    ),
                    child: GestureDetector(
                      onTap: onRightIconPressed,
                      child: Icon(
                        Icons.menu,
                        color: AppColors.brown,
                        size: finalIconSize,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
