import 'package:flutter/material.dart';
import 'package:wildrapport/constants/app_colors.dart';
import 'package:wildrapport/utils/responsive_utils.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Expanded(
      flex: 1,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.darkGreen,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(75),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Image.asset(
                'assets/LogoWildlifeNL.png',
                width: responsive.wp(70),
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              bottom: responsive.sp(-2),
              right: responsive.sp(-1),
              child: Image.asset(
                'assets/gifs/login.gif',
                width: responsive.wp(35),
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
