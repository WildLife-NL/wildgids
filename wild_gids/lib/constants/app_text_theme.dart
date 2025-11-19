import 'package:flutter/material.dart';
// AppColors not needed here since we set explicit black colors for global text theme

class AppTextTheme {
  static final TextTheme textTheme = TextTheme(
    // Titles: Overpass, black and a bit bolder
    titleLarge: const TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Colors.black,
      fontFamily: 'Overpass',
    ),
    titleMedium: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Colors.black,
      fontFamily: 'Overpass',
    ),
    titleSmall: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Colors.black,
      fontFamily: 'Overpass',
    ),
    // Body text: Roboto, black
    bodyLarge: const TextStyle(fontSize: 16, color: Colors.black, fontFamily: 'Roboto'),
    bodyMedium: const TextStyle(fontSize: 14, color: Colors.black, fontFamily: 'Roboto'),
    bodySmall: const TextStyle(fontSize: 12, color: Colors.black, fontFamily: 'Roboto'),
  );
}
