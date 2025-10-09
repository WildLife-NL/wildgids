import 'package:flutter/material.dart';
import 'package:wild_gids/constants/app_colors.dart';

class AppTextTheme {
  static final TextTheme textTheme = TextTheme(
    titleLarge: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: AppColors.dark,
    ),
    titleMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w500,
      color: AppColors.dark,
    ),
    bodyMedium: TextStyle(fontSize: 16, color: AppColors.dark),
  );
}