import 'package:flutter/material.dart';
import 'package:wildrapport/constants/app_colors.dart';

class QuestionnaireWhiteButton extends StatelessWidget {
  final String text;
  final double? height;
  final double? width;
  final Widget? rightWidget;
  final VoidCallback? onPressed;

  const QuestionnaireWhiteButton({
    super.key,
    required this.text,
    this.height,
    this.width,
    this.rightWidget,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            spreadRadius: 0,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                // Expanded widget with centered text
                Expanded(
                  child: Center(
                    child: Text(
                      text,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.brown,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                // Right widget (icon) with some spacing
                if (rightWidget != null) 
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: rightWidget!,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


