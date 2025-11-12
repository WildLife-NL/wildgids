import 'package:flutter/material.dart';
import 'package:wildrapport/constants/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:wildrapport/providers/app_state_provider.dart';
import 'package:wildrapport/screens/profile/profile_screen.dart';

class CustomAppBar extends StatelessWidget {
  final IconData? leftIcon;
  final String? centerText;
  final IconData? rightIcon;
  final Color? iconColor;
  final Color? textColor;
  final double fontScale;
  final double iconScale;
  final double userIconScale;
  final double topPaddingFraction;
  final VoidCallback? onLeftIconPressed;
  final VoidCallback? onRightIconPressed;
  final bool showUserIcon;
  final VoidCallback? onUserIconPressed;
  final bool preserveState;
  final bool useFixedText;

  const CustomAppBar({
    super.key,
    this.leftIcon,
    this.centerText,
    this.rightIcon,
    this.onLeftIconPressed,
    this.onRightIconPressed,
    this.preserveState = true,
    this.showUserIcon = true,
    this.onUserIconPressed,
    this.iconColor,
    this.textColor,
    this.fontScale = 1.0,
    this.iconScale = 1.0,
    this.userIconScale = 1.15,
    this.topPaddingFraction = 0.03,
    this.useFixedText = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final appStateProvider = context.watch<AppStateProvider>();

    // Use fixed centerText if useFixedText is true, otherwise use report type's display text
    final displayText = useFixedText
        ? (centerText ?? '')
        : (appStateProvider.currentReportType?.displayText ?? centerText ?? '');

    // Calculate responsive dimensions
    final double barHeight = screenSize.height * 0.05; // 5% of screen height
    final double minHeight = 24.0;
    final double maxHeight = 40.0;
    final double finalHeight = barHeight.clamp(minHeight, maxHeight);

  // Calculate responsive text size
  final double fontSize = screenSize.width * 0.05; // 5% of screen width
  final double minFontSize = 16.0;
  final double maxFontSize = 24.0;
  final double finalFontSize = (fontSize.clamp(minFontSize, maxFontSize)) * fontScale;

    // Calculate responsive icon size
    final double iconSize = screenSize.width * 0.06; // 6% of screen width
    final double minIconSize = 24.0;
    final double maxIconSize = 32.0;
    final double finalIconSize = (iconSize.clamp(minIconSize, maxIconSize)) * iconScale;
  // Slightly larger profile/person glyph by default (configurable)
  final double userIconSize = finalIconSize * userIconScale;

    final double topPadding = screenSize.height * topPaddingFraction;

    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: Container(
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
                        leftIcon ?? Icons.arrow_back_ios,
                        color: iconColor ?? AppColors.brown,
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
                  color: textColor ?? AppColors.brown,
                  fontSize: finalFontSize,
                  fontFamily: 'Overpass',
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
                      right: screenSize.width * 0.08, // 4% of screen width
                    ),
                    child: GestureDetector(
                      onTap: onRightIconPressed,
                      child: Icon(
                        rightIcon,
                        color: iconColor ?? AppColors.brown,
                        size: finalIconSize,
                      ),
                    ),
                  )
                else if (showUserIcon)
                  Padding(
                    padding: EdgeInsets.only(
                      right: screenSize.width * 0.08, // 4% of screen width
                      bottom: screenSize.height * 0.008, // nudge slightly upward
                    ),
                    child: GestureDetector(
                      onTap: onUserIconPressed ?? () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ProfileScreen(),
                          ),
                        );
                      },
                      child: Icon(
                        Icons.person,
                        color: const Color.fromARGB(255, 0, 0, 0),
                        size: userIconSize,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  }
}
