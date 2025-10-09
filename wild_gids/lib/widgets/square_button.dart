import 'package:flutter/material.dart';

class SquareButton extends StatefulWidget {
  final String imageAssetPath; // path to asset icon image
  final String text;
  final VoidCallback? onPressed;

  const SquareButton({
    Key? key,
    required this.imageAssetPath,
    this.text = "Button Text",
    this.onPressed,
  }) : super(key: key);

  @override
  State<SquareButton> createState() => _SquareButtonState();
}

class _SquareButtonState extends State<SquareButton> {
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
        width: 140,
        height: 200,
        decoration: BoxDecoration(
          color: _isPressed ? darkGreen : white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderGreen,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              widget.imageAssetPath,
              width: 80,
              height: 80,
              color: _isPressed ? white : null, // optional color tint
            ),
            const SizedBox(height: 8),
            Text(
              widget.text,
              style: TextStyle(
                color: _isPressed ? white : Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
