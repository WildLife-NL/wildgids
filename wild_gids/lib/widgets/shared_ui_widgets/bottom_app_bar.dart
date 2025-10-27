import 'package:flutter/material.dart';

class CustomBottomAppBar extends StatelessWidget {
  final VoidCallback? onBackPressed;
  final VoidCallback? onNextPressed;
  final bool showNextButton;

  const CustomBottomAppBar({
    Key? key,
    this.onBackPressed,
    this.onNextPressed,
    this.showNextButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (onBackPressed != null)
              ElevatedButton.icon(
                onPressed: onBackPressed,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Terug'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.black,
                ),
              )
            else
              const SizedBox.shrink(),
            if (showNextButton && onNextPressed != null)
              ElevatedButton.icon(
                onPressed: onNextPressed,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Volgende'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D5016),
                  foregroundColor: Colors.white,
                ),
              )
            else
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
