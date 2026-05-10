import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // old colors (to be removed once all components are updated to use the new standardized colors)
 //static const Color black = Color(0xFF000000);
  static const Color lightGreen = Color(0xFF1F4A14);
  static const Color lightMintGreen = Color(0xFFF1F5F2);
  static const Color offWhite = Color(0xFFFFFFFC);
  static const Color lightMintGreen100 = Color(0xFFFFFFFF);
  static const Color brown900 = Color(0xFF000000);
  //static const Color deepBlue = Color(0xFF01031A);
  //static const Color navy = Color(0xFF0E101F);
  static const Color brown = Color(0xFF000000);
  static const Color brown300 = Color(0xFF000000);
  static const Color brownDark = Color(0xFF000000);
  static const Color timber300 = Color(0xFF20352E);
  static const Color darkGreen = Color(0xFF1C4620);
  static const Color brown600 = Color(0xFF000000);

  // New standardized colors
  // Primary colors
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color darkCharcoal = Color(0xFF333333);
  static const Color black = Color(0xFF000000);

  // Neutral colors
  static const Color white = Colors.white;
  static const Color darkGrey = Color(0xFF666666);
  static const Color mediumGrey = Color(0xFF999999);
  static const Color lightGrey = Color(0xFFF5F6F4);

  // Text colors
  static const Color textPrimary = Color.fromARGB(255, 0, 0, 0);
  static const Color textSecondary = Color.fromARGB(255, 255, 255, 255);
  static const Color textLight = Color(0xFF999999);
  static const Color textExample = Color(0xFFA1B9B9);

  // Background colors
  static const Color backgroundLight = Color(0xFFF5F6F4);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Border colors
  static const Color borderDefault = Color.fromARGB(255, 207, 207, 207);
  static const Color borderLight = Color(0xFFD4D4D4);
  static const Color borderDark = Color(0xFF333333);

  // State colors
  static const Color selected = Color(0xFF4CAF50);
  static const Color selectedDark = Color(0xFF333333);
  static const Color error = Color(0xFFD65A54);
  static const Color success = Color(0xFF388E3C);
  static const Color liveLocation = Color(0xFF0D53FF);
}
