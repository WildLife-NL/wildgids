import 'package:flutter/material.dart';
import 'package:wildrapport/constants/app_colors.dart';
import 'package:wildrapport/utils/responsive_utils.dart';

class EncounterMessageOverlay extends StatelessWidget {
  final String message;
  final String? title;
  final int? severity;

  const EncounterMessageOverlay({
    super.key,
    required this.message,
    this.title,
    this.severity,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    // choose accent based on severity
    final Color accent =
        (severity == 1)
            ? Colors.red.shade700
            : (severity == 2)
            ? Colors.orange.shade700
            : AppColors.darkGreen;

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Material(
        color: Colors.black.withOpacity(0.28),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: responsive.wp(90),
                maxHeight: responsive.hp(20),
              ),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: responsive.wp(5)),
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.wp(3),
                  vertical: responsive.hp(1.2),
                ),
                decoration: BoxDecoration(
                  color: AppColors.lightMintGreen.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(responsive.sp(1.75)),
                  border: Border.all(
                    color: AppColors.darkGreen,
                    width: responsive.sp(0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon / asset (smaller)
                    Container(
                      width: responsive.sp(5),
                      height: responsive.sp(5),
                      margin: EdgeInsets.only(
                        right: responsive.wp(2.5),
                        top: responsive.hp(0.25),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          responsive.sp(0.75),
                        ),
                        child: Image.asset(
                          'assets/icons/animalmeet.png',
                          fit: BoxFit.cover,
                          errorBuilder:
                              (c, e, s) =>
                                  Icon(Icons.pets, color: accent, size: 32),
                        ),
                      ),
                    ),
                    // Texts (constrained)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if ((title ?? '').isNotEmpty)
                            Text(
                              title!,
                              style: TextStyle(
                                color: AppColors.darkGreen,
                                fontSize: responsive.fontSize(14),
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if ((title ?? '').isNotEmpty)
                            SizedBox(height: responsive.hp(0.5)),
                          Text(
                            message,
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: responsive.fontSize(13),
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Close X (compact)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: InkResponse(
                        radius: 18,
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
