import 'package:flutter/material.dart';
import 'package:wildrapport/constants/app_colors.dart';
import 'package:wildrapport/screens/profile/profile_screen.dart';

class TopContainer extends StatelessWidget {
  final String userName;
  final double height;
  final double welcomeFontSize;
  final double usernameFontSize;
  final bool showUserIcon;
  final VoidCallback? onUserIconPressed;

  const TopContainer({
    super.key,
    required this.userName,
    required this.height,
    required this.welcomeFontSize,
    required this.usernameFontSize,
    this.showUserIcon = true,
    this.onUserIconPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.darkGreen,
            borderRadius: BorderRadius.zero, // straight bottom edge to match mock
          ),
          child: Center(
            child: Padding(
              padding: EdgeInsets.only(top: height * 0.06),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Welkom Bij Wild Gids',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.offWhite,
                      fontSize: welcomeFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: height * 0.03),
                  Text(
                    userName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.offWhite,
                      fontSize: usernameFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showUserIcon)
          Positioned(
            right: 12,
            // move icon a bit lower for visual alignment
            top: height * 0.12,
            child: GestureDetector(
              onTap: onUserIconPressed ?? () {
                debugPrint('[TopContainer] user icon tapped');
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ProfileScreen(),
                  ),
                );
              },
              child: Icon(
                Icons.person,
                color: AppColors.offWhite,
                // slightly smaller than before
                size: height * 0.14,
              ),
            ),
          ),
      ],
    );
  }
}
