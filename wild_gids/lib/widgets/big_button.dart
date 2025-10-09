import 'package:flutter/material.dart';

class BigButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;

  const BigButton({
    Key? key,
    this.text = "Button Text",
    this.onPressed,
  }) : super(key: key);

  @override
  State<BigButton> createState() => _BigButtonState();
}

class _BigButtonState extends State<BigButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final Color darkGreen = const Color(0xFF234F1E);
    final Color white = Colors.white;
    final Color borderGreen = const Color(0xFF234F1E);

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
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _isPressed ? darkGreen : white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: borderGreen,
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          widget.text,
          style: TextStyle(
            color: _isPressed ? white : Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}