import 'package:flutter/material.dart';
import 'package:wildrapport/constants/app_colors.dart';
import 'package:wildrapport/widgets/shared_ui_widgets/white_bulk_button.dart';
import 'package:wildrapport/utils/responsive_utils.dart';

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
    final responsive = context.responsive;

    // Fixed sizes for consistent button appearance across the entire app
    const double buttonHeight = 56.0;
    const double buttonWidth = 280.0;
    const double buttonFontSize = 16.0;
    
    final double barHeight = buttonHeight + 40; // padding around button
    final double finalHeight = barHeight;

    return Container(
      height: finalHeight,
      color: Colors.transparent, // Make container background transparent
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: responsive.spacing(10)),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (showBackButton)
                  SizedBox(
                    width: showNextButton ? buttonWidth * 0.45 : buttonWidth,
                    height: buttonHeight,
                    child: WhiteBulkButton(
                      text: 'Vorige',
                      showIcon: false,
                      height: buttonHeight,
                      backgroundColor: AppColors.lightMintGreen100,
                      borderColor: AppColors.brown,
                      hoverBackgroundColor: AppColors.brown,
                      hoverBorderColor: AppColors.lightMintGreen100,
                      textStyle: TextStyle(
                        fontFamily: 'Roboto',
                        color: Colors.black,
                        fontSize: buttonFontSize,
                        fontWeight: FontWeight.w600,
                      ),
                      showShadow: false,
                      onPressed: _handleBackPress,
                    ),
                  ),
                if (showBackButton && showNextButton)
                  SizedBox(width: responsive.wp(4)),
                if (showNextButton)
                  SizedBox(
                    width: showBackButton ? buttonWidth * 0.45 : buttonWidth,
                    height: buttonHeight,
                    child: WhiteBulkButton(
                      text: 'Volgende',
                      showIcon: false,
                      height: buttonHeight,
                      backgroundColor: AppColors.lightMintGreen100,
                      borderColor: AppColors.brown,
                      hoverBackgroundColor: AppColors.brown,
                      hoverBorderColor: AppColors.lightMintGreen100,
                      textStyle: TextStyle(
                        fontFamily: 'Roboto',
                        color: Colors.black,
                        fontSize: buttonFontSize,
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
