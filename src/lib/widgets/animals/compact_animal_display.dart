import 'package:flutter/material.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_model.dart';
import 'package:wildgids/constants/app_colors.dart';
import 'package:wildgids/utils/responsive_utils.dart';

class CompactAnimalDisplay extends StatelessWidget {
  final AnimalModel animal;
  final double? height;

  const CompactAnimalDisplay({super.key, required this.animal, this.height});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    // Calculate responsive dimensions
    final double calculatedHeight =
        height ?? responsive.hp(17); // 17% of screen height
    final double minHeight = responsive.sp(13);
    final double maxHeight = responsive.sp(20);
    final double finalHeight = calculatedHeight.clamp(minHeight, maxHeight);

    // Calculate responsive text size
    final double finalFontSize = responsive.fontSize(16);

    // Calculate responsive padding
    final double finalPadding = responsive.spacing(12);

    return Container(
      width: finalHeight * 0.85, // Increased from 0.8 to 0.85
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(finalPadding),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: finalPadding / 3,
            offset: Offset(0, finalPadding / 6),
          ),
        ],
      ),
      padding: EdgeInsets.all(finalPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            // Use a smaller, consistent radius for images so corners are less rounded
            borderRadius: BorderRadius.circular(responsive.sp(0.75)),
            child:
                animal.animalImagePath != null
                    ? SizedBox(
                      height: finalHeight - (finalPadding * 2),
                      child: Image.asset(
                        animal.animalImagePath!,
                        fit: BoxFit.contain,
                      ),
                    )
                    : SizedBox(
                      height: finalHeight - (finalPadding * 2),
                      child: Icon(
                        Icons.help_outline,
                        color: AppColors.brown,
                        size: (finalHeight - (finalPadding * 2)) * 0.3,
                      ),
                    ),
          ),
          Padding(
            padding: EdgeInsets.only(top: finalPadding * 0.75),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                animal.animalName,
                style: TextStyle(
                  color: AppColors.brown,
                  fontSize: finalFontSize,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

