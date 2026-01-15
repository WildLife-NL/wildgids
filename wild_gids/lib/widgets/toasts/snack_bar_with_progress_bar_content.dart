import 'package:flutter/material.dart';
import 'package:wildgids/widgets/toasts/snack_bar_text.dart';

class SnackBarWithProgressBarContent extends StatelessWidget {
  final String message;
  final Duration duration;

  const SnackBarWithProgressBarContent({
    super.key,
    required this.message,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // This ensures the snack bar content has enough space for both text and progress bar
      height: 56 + 4, // 56 for content height, 4 for progress bar
      child: Stack(
        children: [
          // Text and icon row (centered vertically)
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              child: Align(
                alignment: Alignment.center,
                child: SnackBarText(message: message),
              ),
            ),
          ),
          // Progress bar at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: duration,
              builder:
                  (context, value, _) => LinearProgressIndicator(
                    value: value,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF34C759),
                    ),
                    minHeight: 4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

