import 'package:flutter/material.dart';
import 'package:wildrapport/constants/app_colors.dart';

class AppTextTheme {
  static final TextTheme textTheme = TextTheme(
    titleLarge: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: AppColors.brown,
      fontFamily: 'Overpass',
    ),
    titleMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w500,
      color: AppColors.brown,
      fontFamily: 'Roboto',
    ),
    bodyMedium: TextStyle(fontSize: 16, color: AppColors.brown, fontFamily: 'Roboto'),
  );
}
