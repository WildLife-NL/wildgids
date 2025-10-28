import 'package:flutter/material.dart';
import 'package:wildrapport/constants/app_colors.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

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
                width: screenWidth * 0.7,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              bottom: -20,
              right: -10,
              child: Image.asset(
                'assets/gifs/login.gif',
                width: screenWidth * 0.35,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
