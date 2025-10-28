import 'package:flutter/material.dart';
import 'package:wildrapport/constants/app_colors.dart';

class CustomBottomAppBar extends StatelessWidget {
  final VoidCallback onBackPressed;
  final VoidCallback? onNextPressed;
  final bool showNextButton;
  final bool showBackButton;

  const CustomBottomAppBar({
    super.key,
    required this.onBackPressed,
    this.onNextPressed,
    this.showNextButton = true,
    this.showBackButton = true,
  });

  void _handleBackPress() {
    debugPrint('CustomBottomAppBar: Back button pressed');
    onBackPressed();
  }

  void _handleNextPress() {
    debugPrint('CustomBottomAppBar: Next button pressed');
    onNextPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    final double barHeight = screenSize.height * 0.1;
    final double minHeight = 80.0;
    final double maxHeight = 100.0;

    final double fontSize = screenSize.width * 0.05;
    final double minFontSize = 18.0;
    final double maxFontSize = 24.0;

    final double iconSize = screenSize.width * 0.08;
    final double minIconSize = 28.0;
    final double maxIconSize = 36.0;

    final double finalHeight = barHeight.clamp(minHeight, maxHeight);
    final double finalFontSize = fontSize.clamp(minFontSize, maxFontSize);
    final double finalIconSize = iconSize.clamp(minIconSize, maxIconSize);
    final double horizontalPadding = screenSize.width * 0.06;

    return Container(
      height: finalHeight,
      color: Colors.transparent, // Make container background transparent
      child: SafeArea(
        child: Row(
          mainAxisAlignment:
              showNextButton && showBackButton
                  ? MainAxisAlignment.spaceBetween
                  : showNextButton
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
          children: [
            if (showBackButton)
              GestureDetector(
                onTap: _handleBackPress,
                child: Padding(
                  padding: EdgeInsets.only(left: horizontalPadding),
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_back_ios,
                        color: AppColors.brown,
                        size: finalIconSize,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      SizedBox(width: screenSize.width * 0.03),
                      Text(
                        'Terug',
                        style: TextStyle(
                          color: AppColors.brown,
                          fontSize: finalFontSize,
                          fontWeight: FontWeight.w600,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (showNextButton)
              GestureDetector(
                onTap: _handleNextPress,
                child: Padding(
                  padding: EdgeInsets.only(right: horizontalPadding),
                  child: Row(
                    children: [
                      Text(
                        'Volgende',
                        style: TextStyle(
                          color: AppColors.brown,
                          fontSize: finalFontSize,
                          fontWeight: FontWeight.w600,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: screenSize.width * 0.03),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: AppColors.brown,
                        size: finalIconSize,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
