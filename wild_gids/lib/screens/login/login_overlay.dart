import 'package:flutter/material.dart';
import 'package:wildrapport/constants/app_colors.dart';
import 'package:wildrapport/constants/app_text_theme.dart';

class LoginOverlay extends StatelessWidget {
  const LoginOverlay({super.key});

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
                          Icons.exit_to_app,
                          size: 32,
                          color: Colors.black,
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
                            'Heeft u geen account?',
                            style: AppTextTheme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Voer uw e-mailadres in. U ontvangt een verificatiecode per e-mail. '
                            'Als er al een account bestaat, wordt u ingelogd. Zo niet, dan wordt er '
                            'automatisch een account voor u aangemaakt en direct ingelogd.',
                            style: AppTextTheme.textTheme.bodyMedium?.copyWith(
                              
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
