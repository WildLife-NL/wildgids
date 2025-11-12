import 'package:flutter/material.dart';
import 'package:wildrapport/constants/app_colors.dart';
import 'package:wildrapport/constants/app_text_theme.dart';

class ReportButton extends StatefulWidget {
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
  State<ReportButton> createState() => _ReportButtonState();
}

class _ReportButtonState extends State<ReportButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  void _onEnter(PointerEvent _) {
    setState(() => _isHovered = true);
  }

  void _onExit(PointerEvent _) {
    setState(() => _isHovered = false);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final double iconSize = screenSize.width * 0.25;

    final Color baseColor = AppColors.lightMintGreen; // page background color
    final Color hoverColor = AppColors.darkGreen;

    return MouseRegion(
      onEnter: _onEnter,
      onExit: _onExit,
      child: GestureDetector(
        onTap: widget.onPressed,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          decoration: BoxDecoration(
            // pressed takes precedence over hover so taps immediately show dark green
            color: (_isPressed || _isHovered) ? hoverColor : baseColor,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: AppColors.darkGreen,
              width: 2,
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: EdgeInsets.all(screenSize.width * 0.04),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: iconSize,
                          child: Center(
                            child: widget.icon != null
                                ? Icon(
                                    widget.icon,
                                    size: iconSize * 0.6,
                                    color: (_isPressed || _isHovered)
                                        ? Colors.white
                                        : AppColors.brown,
                                  )
                                : Image.asset(
                                    widget.image!,
                                    fit: BoxFit.contain,
                                    width: iconSize,
                                    height: iconSize,
                                    // tint the image white on hover/press; requires monochrome/transparent PNGs
                                    color: (_isPressed || _isHovered) ? Colors.white : null,
                                    colorBlendMode: BlendMode.srcIn,
                                  ),
                          ),
                        ),
                        SizedBox(height: screenSize.height * 0.02),
                        Text(
                          widget.text,
                          style: AppTextTheme.textTheme.titleMedium?.copyWith(
                            fontSize: 18,
                            color: (_isPressed || _isHovered) ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Arrow intentionally removed per design
            ],
          ),
        ),
      ),
    );
  }
}

