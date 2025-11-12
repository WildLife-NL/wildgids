import 'package:flutter/material.dart';
import 'package:wildrapport/constants/app_colors.dart';
import 'package:wildrapport/widgets/shared_ui_widgets/white_bulk_button.dart';

class CustomBottomAppBar extends StatelessWidget {
  final VoidCallback? onBackPressed;
  final VoidCallback? onNextPressed;
  final bool showNextButton;
  final bool showBackButton;

  const CustomBottomAppBar({
    super.key,
    this.onBackPressed,
    this.onNextPressed,
    this.showNextButton = true,
    this.showBackButton = true,
  });

  void _handleBackPress() {
    debugPrint('CustomBottomAppBar: Back button pressed');
    onBackPressed?.call();
  }

  void _handleNextPress() {
    debugPrint('CustomBottomAppBar: Next button pressed');
    onNextPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    final double barHeight = screenSize.height * 0.12;
    final double minHeight = 100.0;
    final double maxHeight = 130.0;

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
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Center(
            child: Row(
              mainAxisAlignment:
                  showNextButton && showBackButton
                      ? MainAxisAlignment.spaceBetween
                      : showNextButton
                      ? MainAxisAlignment.center
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
                          ),
                          SizedBox(width: screenSize.width * 0.03),
                          Text(
                            'Terug',
                            style: TextStyle(
                              color: AppColors.brown,
                              fontSize: finalFontSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (showNextButton)
                  SizedBox(
                    width: 220,
                    height: 50,
                    child: WhiteBulkButton(
                      text: 'Volgende',
                      showIcon: false,
                      height: 50,
                      backgroundColor: AppColors.lightMintGreen100,
                      borderColor: AppColors.brown,
                      hoverBackgroundColor: AppColors.brown,
                      hoverBorderColor: AppColors.lightMintGreen100,
                      textStyle: const TextStyle(
                        fontFamily: 'Roboto',
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      showShadow: false,
                      onPressed: _handleNextPress,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
