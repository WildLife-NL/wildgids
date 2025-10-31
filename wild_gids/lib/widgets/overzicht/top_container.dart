import 'package:flutter/material.dart';
import 'package:wildrapport/constants/app_colors.dart';

class TopContainer extends StatelessWidget {
  final String userName;
  final double height;
  final double welcomeFontSize;
  final double usernameFontSize;

  const TopContainer({
    super.key,
    required this.userName,
    required this.height,
    required this.welcomeFontSize,
    required this.usernameFontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.darkGreen,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(75)),
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
          Padding(
            padding: EdgeInsets.only(
              left: MediaQuery.of(context).size.width * 0.05,
              top: height * 0.15,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welkom Bij Wild Gids',
                  style: TextStyle(
                    color: AppColors.offWhite,
                    fontSize: welcomeFontSize,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: height * 0.03),
                Text(
                  userName,
                  style: TextStyle(
                    color: AppColors.offWhite,
                    fontSize: usernameFontSize,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 15,
            right: 0,
            left: 0,
            child: Center(
              child: Image.asset(
                'assets/LogoWildlifeNL.png',
                width: MediaQuery.of(context).size.width * 0.7,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
