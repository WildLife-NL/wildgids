import 'package:flutter/material.dart';
import 'package:wildrapport/constants/app_colors.dart';
import 'package:wildrapport/widgets/toasts/snack_bar_with_progress_bar_content.dart';

class SnackBarWithProgressBar {
  static void show({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 2),
  }) {
    final snackBar = SnackBar(
      content: SnackBarWithProgressBarContent(
        message: message,
        duration: duration,
      ),
      duration: duration,
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.offWhite,
      padding: const EdgeInsets.all(0),
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).size.height - 205,
        right: 20,
        left: 20,
      ),
    );

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}