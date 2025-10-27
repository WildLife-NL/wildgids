import 'package:flutter/material.dart';

class SmallButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;

  const SmallButton({
    Key? key,
    this.text = "Button Text",
    this.onPressed,
  }) : super(key: key);

  @override
  State<SmallButton> createState() => _SmallButtonState();
}

class _SmallButtonState extends State<SmallButton> {
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
        height: 32,
        width: 100,
        decoration: BoxDecoration(
          color: _isPressed ? darkGreen : white,
          borderRadius: BorderRadius.circular(24), // Half of 28
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
            fontSize: 16, // Half of 22
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
