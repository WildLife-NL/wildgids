import 'package:flutter/material.dart';
import 'package:wildgids/constants/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/providers/app_state_provider.dart';
import 'package:wildgids/screens/profile/profile_screen.dart';
import 'package:wildgids/utils/responsive_utils.dart';

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
    final responsive = context.responsive;
    final appStateProvider = context.watch<AppStateProvider>();

    // Use fixed centerText if useFixedText is true, otherwise use report type's display text
    final displayText =
        useFixedText
            ? (centerText ?? '')
            : (appStateProvider.currentReportType?.displayText ??
                centerText ??
                '');

    // Calculate responsive dimensions using ResponsiveUtils
    final double barHeight = responsive.hp(3.5); // 3.5% of screen height
    final double minHeight = responsive.sp(2);
    final double maxHeight = responsive.sp(3.5);
    final double finalHeight = barHeight.clamp(minHeight, maxHeight) + 6;

    // Calculate responsive text size
    final double finalFontSize = responsive.fontSize(14) * fontScale;

    // Calculate responsive icon size
    final double finalIconSize = responsive.sp(2.8) * iconScale;
    // Slightly larger profile/person glyph by default (configurable)
    final double userIconSize = finalIconSize * userIconScale;

    final double topPadding = responsive.hp(topPaddingFraction * 100);

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
                        left: responsive.wp(4), // 4% of screen width
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
                        right: responsive.wp(8), // 8% of screen width
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
                        right: responsive.wp(8), // 8% of screen width
                        bottom: responsive.hp(0.8), // nudge slightly upward
                      ),
                      child: GestureDetector(
                        onTap:
                            onUserIconPressed ??
                            () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ProfileScreen(),
                                ),
                              );
                            },
                        child: Icon(
                          Icons.person,
                          color: iconColor ?? AppColors.brown,
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

