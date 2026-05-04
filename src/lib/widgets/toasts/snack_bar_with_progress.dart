import 'package:flutter/material.dart';
import 'package:wildgids/constants/app_colors.dart';
import 'package:wildgids/widgets/toasts/snack_bar_text.dart';
import 'package:wildgids/utils/responsive_utils.dart';

class SnackBarWithProgress extends StatelessWidget {
  const SnackBarWithProgress({super.key, required this.message});

  final String message;

  static void show({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 2),
  }) {
    final responsive = context.responsive;
    final snackBar = SnackBar(
      content: SnackBarText(message: message),
      duration: duration,
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.offWhite,
      padding: EdgeInsets.symmetric(
        horizontal: responsive.spacing(16),
        vertical: responsive.spacing(12),
      ),
      margin: EdgeInsets.only(
        bottom: responsive.height - responsive.hp(25),
        right: responsive.spacing(20),
        left: responsive.spacing(20),
      ),
    );

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return SnackBarText(message: message);
  }
}

