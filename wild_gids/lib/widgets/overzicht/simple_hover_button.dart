import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wildgids/constants/app_colors.dart';

class SimpleHoverButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final double height;
  final double? width;
  final TextStyle? textStyle;
  final Color borderColor;
  final Color backgroundColor;

  const SimpleHoverButton({
    super.key,
    required this.text,
    this.onPressed,
    this.height = 48,
    this.width,
    this.textStyle,
    this.borderColor = AppColors.darkGreen,
    this.backgroundColor = Colors.white,
  });

  @override
  State<SimpleHoverButton> createState() => _SimpleHoverButtonState();
}

class _SimpleHoverButtonState extends State<SimpleHoverButton> {
  bool _hovering = false;
  bool _pressed = false;

  void _setHover(bool value) {
    if (!kIsWeb &&
        defaultTargetPlatform != TargetPlatform.macOS &&
        defaultTargetPlatform != TargetPlatform.windows &&
        defaultTargetPlatform != TargetPlatform.linux) {
      // On mobile platforms, ignore hover.
      return;
    }
    setState(() => _hovering = value);
  }

  @override
  Widget build(BuildContext context) {
    final bool active = _hovering || _pressed;
    final Color bg = active ? AppColors.darkGreen : widget.backgroundColor;
    final Color txtColor =
        active ? Colors.white : (widget.textStyle?.color ?? Colors.black);

    return MouseRegion(
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      child: GestureDetector(
        onTap: widget.onPressed,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: widget.height,
          width: widget.width ?? double.infinity,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(widget.height / 2),
            border: Border.all(color: widget.borderColor, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.text,
            style:
                widget.textStyle?.copyWith(color: txtColor) ??
                TextStyle(
                  color: txtColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ),
    );
  }
}

