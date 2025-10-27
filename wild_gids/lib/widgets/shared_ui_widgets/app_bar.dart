import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget {
  final IconData? leftIcon;
  final String? centerText;
  final IconData? rightIcon;
  final VoidCallback? onLeftIconPressed;
  final VoidCallback? onRightIconPressed;

  const CustomAppBar({
    Key? key,
    this.leftIcon,
    this.centerText,
    this.rightIcon,
    this.onLeftIconPressed,
    this.onRightIconPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (leftIcon != null)
            IconButton(
              icon: Icon(leftIcon),
              onPressed: onLeftIconPressed,
            )
          else
            const SizedBox(width: 48),
          if (centerText != null)
            Text(
              centerText!,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          if (rightIcon != null)
            IconButton(
              icon: Icon(rightIcon),
              onPressed: onRightIconPressed,
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }
}
