import 'package:flutter/material.dart';
import 'package:wildgids/constants/app_colors.dart';
import 'package:wildgids/constants/app_text_theme.dart';
import 'package:wildgids/utils/responsive_utils.dart';

class LoginOverlay extends StatelessWidget {
  const LoginOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Material(
        color: AppColors.lightMintGreen.withValues(alpha: 0.5),
        child: Center(
          child: GestureDetector(
            onTap:
                () {}, // Prevents taps on the container from closing the overlay
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: responsive.wp(5)),
              constraints: BoxConstraints(maxWidth: responsive.wp(80)),
              decoration: BoxDecoration(
                color: AppColors.offWhite,
                borderRadius: BorderRadius.circular(responsive.sp(3.1)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: responsive.hp(1.5)),
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
                          size: responsive.sp(4),
                          color: Colors.black,
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      iconSize: responsive.sp(6),
                    ),
                  ),
                  Flexible(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        responsive.wp(5),
                        responsive.hp(1),
                        responsive.wp(5),
                        responsive.hp(2.5),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Hebt u nog geen account?',
                            style: AppTextTheme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: responsive.fontSize(24),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: responsive.spacing(20)),
                          Text(
                            'Geef uw e-mailadres op en bevestig met de knop \'Aanmelden\'. '
                            'U ontvangt een verificatiecode per e-mail welke u dan in deze app invoert. '
                            'Indien er nog geen account bestaat voor dit e-mailadres wordt deze automatisch geregistreerd. '
                            'Daarna bent u aangemeld.',
                            style: AppTextTheme.textTheme.bodyMedium?.copyWith(
                              fontSize: responsive.fontSize(14),
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

