import 'package:flutter/material.dart';
import 'package:wildrapport/utils/responsive_utils.dart';

class SnackBarText extends StatelessWidget {
  final String message;
  final Widget? trailing;

  const SnackBarText({super.key, required this.message, this.trailing});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: responsive.wp(80)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: responsive.sp(2.5),
            ),
            SizedBox(width: responsive.spacing(12)),
            Flexible(
              // Flexible lets text wrap and limits width within Row
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Roboto',
                ),
              ),
            ),
            if (trailing != null) ...[
              SizedBox(width: responsive.spacing(12)),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
