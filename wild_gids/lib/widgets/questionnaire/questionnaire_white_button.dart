import 'package:flutter/material.dart';
import 'package:wildrapport/constants/app_colors.dart';
import 'package:wildrapport/utils/responsive_utils.dart';

class QuestionnaireWhiteButton extends StatefulWidget {
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
  State<QuestionnaireWhiteButton> createState() =>
      _QuestionnaireWhiteButtonState();
}

class _QuestionnaireWhiteButtonState extends State<QuestionnaireWhiteButton> {
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
    final responsive = context.responsive;
    final bool isActive = _isPressed || _isHovered;

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
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            color: isActive ? AppColors.darkGreen : Colors.white,
            borderRadius: BorderRadius.circular(responsive.sp(2.5)),
            border: Border.all(
              color: AppColors.darkGreen,
              width: responsive.sp(0.2),
            ),
          ),
          child: Center(
            child: Text(
              widget.text,
              style: TextStyle(
                fontSize: responsive.fontSize(16),
                fontFamily: 'Roboto',
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : Colors.black,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
