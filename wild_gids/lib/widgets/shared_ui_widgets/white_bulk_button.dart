import 'package:flutter/material.dart';
import 'package:wildrapport/constants/app_colors.dart';
import 'package:wildrapport/constants/app_text_theme.dart';
import 'package:wildrapport/widgets/shared_ui_widgets/circle_icon_container.dart';

class WhiteBulkButton extends StatelessWidget {
  final String text;
  final Widget? leftWidget;
  final Widget? rightWidget;
  final VoidCallback? onPressed;
  final double height;
  final double? width; // Add width parameter
  final bool showIcon;
  final TextStyle? textStyle;
  final double? fontSize;
  final FontWeight? fontWeight;
  final TextAlign textAlign;
  final Color? backgroundColor; // Add this line

  const WhiteBulkButton({
    super.key,
    required this.text,
    this.leftWidget,
    this.rightWidget,
    this.onPressed,
    this.height = 120,
    this.width, // Add width parameter
    this.showIcon = true,
    this.textStyle,
    this.fontSize,
    this.fontWeight,
    this.textAlign = TextAlign.center,
    this.backgroundColor, // Add this line
  });

  @override
  Widget build(BuildContext context) {
    // Base style from theme
    final baseStyle = AppTextTheme.textTheme.titleLarge?.copyWith(
      shadows: [
        Shadow(
          color: Colors.black.withValues(alpha: 0.25),
          offset: const Offset(0, 2),
          blurRadius: 4,
        ),
      ],
    );

    // Combine styles in order of precedence
    final effectiveStyle = baseStyle
        ?.copyWith(
          fontSize: fontSize ?? textStyle?.fontSize ?? baseStyle.fontSize,
          fontWeight:
              fontWeight ?? textStyle?.fontWeight ?? baseStyle.fontWeight,
          color: textStyle?.color ?? baseStyle.color,
        )
        .merge(textStyle);

    return Container(
      height: height,
      width: width ?? double.infinity, // Use width parameter if provided
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.offWhite, // Modify this line
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
          splashColor: AppColors.brown.withValues(alpha: 0.1),
          highlightColor: AppColors.brown.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (leftWidget != null) leftWidget! else const SizedBox(),
                Expanded(
                  child: Text(
                    text,
                    textAlign: textAlign,
                    style: effectiveStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (rightWidget != null)
                  rightWidget!
                else if (showIcon)
                  CircleIconContainer(
                    icon: Icons.arrow_forward_ios,
                    iconColor: AppColors.brown,
                    size: 48,
                    iconSize: 28,
                    backgroundColor:
                        backgroundColor ?? AppColors.offWhite, // Add this line
                  )
                else
                  const SizedBox(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
