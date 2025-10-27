import 'package:flutter/material.dart';
import 'package:widgets/constants/app_colors.dart';

class WhiteBulkButton extends StatelessWidget {
  final String text;
  final double height;
  final double? fontSize;
  final FontWeight? fontWeight;
  final TextAlign? textAlign;
  final bool showIcon;
  final Color? backgroundColor;
  final VoidCallback? onPressed;

  const WhiteBulkButton({
    super.key,
    required this.text,
    this.height = 64.5,
    this.fontSize,
    this.fontWeight,
    this.textAlign,
    this.showIcon = false,
    this.backgroundColor,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor ?? Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  spreadRadius: 0,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(color: AppColors.brown.withValues(alpha: 0.3)),
            ),
            alignment: Alignment.center,
            child: Text(
              text,
              textAlign: textAlign ?? TextAlign.center,
              style: TextStyle(
                fontSize: fontSize ?? 16,
                fontWeight: fontWeight ?? FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
