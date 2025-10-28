import 'package:flutter/material.dart';
import 'package:wildrapport/constants/app_colors.dart';
import 'package:wildrapport/constants/app_text_theme.dart';

class ReportButton extends StatelessWidget {
  final String? image;
  final IconData? icon;
  final String text;
  final VoidCallback onPressed;
  final bool isFullWidth;

  const ReportButton({
    super.key,
    this.image,
    this.icon,
    required this.text,
    required this.onPressed,
    this.isFullWidth = false,
  }) : assert(
         image != null || icon != null,
         'Either image or icon must be provided',
       );

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final double iconSize = screenSize.width * 0.25;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.offWhite,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: EdgeInsets.all(screenSize.width * 0.04),
                child: SingleChildScrollView( // Add this to make content scrollable
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min, // Add this to prevent overflow
                    children: [
                      SizedBox(
                        height: iconSize,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            icon != null
                                ? Icon(
                                  icon,
                                  size: iconSize * 0.6,
                                  color: AppColors.brown,
                                )
                                : Image.asset(image!, fit: BoxFit.contain),
                          ],
                        ),
                      ),
                      SizedBox(height: screenSize.height * 0.02),
                      Text(
                        text,
                        style: AppTextTheme.textTheme.titleMedium?.copyWith(
                          fontSize: 15,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment:
                  isFullWidth ? Alignment.bottomCenter : Alignment.bottomRight,
              child: Padding(
                padding: EdgeInsets.all(screenSize.width * 0.04),
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.brown,
                  size: screenSize.width * 0.06,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
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

