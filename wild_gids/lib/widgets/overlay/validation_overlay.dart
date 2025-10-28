import 'package:flutter/material.dart';
import 'package:wildrapport/constants/app_colors.dart';
import 'package:wildrapport/constants/app_text_theme.dart';

class ValidationOverlay extends StatelessWidget {
  final List<String> messages;

  const ValidationOverlay({super.key, required this.messages});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Material(
        color: AppColors.lightMintGreen.withValues(alpha: 0.5),
        child: Center(
          child: GestureDetector(
            onTap:
                () {}, // Prevents taps on the container from closing the overlay
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              constraints: const BoxConstraints(maxWidth: 500),
              decoration: BoxDecoration(
                color: AppColors.offWhite,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    spreadRadius: 0,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: IconButton(
                      icon: ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black,
                              Colors.black.withValues(alpha: 0.8),
                            ],
                          ).createShader(bounds);
                        },
                        child: Icon(
                          Icons.warning_amber_rounded,
                          size: 32,
                          color: Colors.black,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      iconSize: 50,
                    ),
                  ),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Let op',
                            style: AppTextTheme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  offset: const Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            messages.join('\n'),
                            style: AppTextTheme.textTheme.bodyMedium?.copyWith(
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  offset: const Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
