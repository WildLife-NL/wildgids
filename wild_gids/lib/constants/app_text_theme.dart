import 'package:flutter/material.dart';
import 'package:widgets/constants/app_colors.dart';


class AppTextTheme {
  static final TextTheme textTheme = TextTheme(
    titleLarge: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: AppColors.darkGreen, // Ensure this color exists
    ),
    titleMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w500,
      color: AppColors.darkGreen,
    ),
    bodyMedium: TextStyle(
      fontSize: 16,
      color: AppColors.darkGreen,
    ),
  );
}
