import 'package:flutter/material.dart';

class FilterButton extends StatefulWidget {
  final String text;
  final bool selected;
  final VoidCallback? onPressed;

  const FilterButton({
    Key? key,
    this.text = "Button Text",
    this.selected = false,
    this.onPressed,
  }) : super(key: key);

  @override
  State<FilterButton> createState() => _FilterButtonState();
}

class _FilterButtonState extends State<FilterButton> {
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
        height: 56,
         width: 200,
        decoration: BoxDecoration(
          color: active ? peach : white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: borderPeach,
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          widget.text,
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
