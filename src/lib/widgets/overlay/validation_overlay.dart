import 'package:flutter/material.dart';
import 'package:wildgids/constants/app_colors.dart';
import 'package:wildgids/utils/responsive_utils.dart';

class ValidationOverlay extends StatelessWidget {
  final List<String> messages;

  const ValidationOverlay({super.key, required this.messages});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Material(
        color: AppColors.lightMintGreen.withValues(alpha: 0.5),
        child: Center(
          child: GestureDetector(
            onTap:
                () {}, // Prevents taps on the container from closing the overlay
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: responsive.wp(5)),
              constraints: BoxConstraints(maxWidth: responsive.wp(80)),
              decoration: BoxDecoration(
                color: AppColors.offWhite,
                borderRadius: BorderRadius.circular(responsive.sp(3.1)),
                border: Border.all(
                  color: Colors.red,
                  width: responsive.sp(0.25),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: responsive.hp(1.5)),
                    child: IconButton(
                      icon: Icon(
                        Icons.warning_amber_rounded,
                        size: responsive.sp(6),
                        color: Colors.red,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      iconSize: responsive.sp(6),
                    ),
                  ),
                  Flexible(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        responsive.wp(5),
                        responsive.hp(1),
                        responsive.wp(5),
                        responsive.hp(2.5),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Let op',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.bold,
                              fontSize: responsive.fontSize(18),
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: responsive.spacing(12)),
                          Text(
                            messages.join('\n'),
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: responsive.fontSize(16),
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

