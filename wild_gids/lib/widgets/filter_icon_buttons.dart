import 'package:flutter/material.dart';

class GenderButton extends StatefulWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback? onPressed;

  const GenderButton({
    Key? key,
    required this.icon,
    this.selected = false,
    this.onPressed,
  }) : super(key: key);

  @override
  State<GenderButton> createState() => _GenderButtonState();
}

class _GenderButtonState extends State<GenderButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final Color peach = const Color(0xFFF4D1B7);
    final Color white = Colors.white;
    final Color borderPeach = const Color(0xFFF4D1B7);

    final bool active = _isPressed || widget.selected;

    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isPressed = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          _isPressed = false;
        });
        if (widget.onPressed != null) widget.onPressed!();
      },
      onTapCancel: () {
        setState(() {
          _isPressed = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: 64,
        width: 64,
        decoration: BoxDecoration(
          color: active ? peach : white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: borderPeach,
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          widget.icon,
          color: Colors.black,
          size: 40,
        ),
      ),
    );
  }
}