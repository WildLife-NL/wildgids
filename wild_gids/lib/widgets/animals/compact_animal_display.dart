import 'package:flutter/material.dart';
import 'package:widgets/models/animal_waarneming_models/animal_model.dart';
import 'package:widgets/constants/app_colors.dart';

class CompactAnimalDisplay extends StatelessWidget {
  final AnimalModel animal;
  final double? height;

  const CompactAnimalDisplay({super.key, required this.animal, this.height});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    // Calculate responsive dimensions
    final double calculatedHeight =
        height ?? screenSize.height * 0.17; // Increased from 0.15 to 0.17
    final double minHeight = 110.0; // Increased from 100.0
    final double maxHeight = 160.0; // Increased from 150.0
    final double finalHeight = calculatedHeight.clamp(minHeight, maxHeight);

    // Calculate responsive text size
    final double fontSize = screenSize.width * 0.04; // 4% of screen width
    final double minFontSize = 14.0;
    final double maxFontSize = 18.0;
    final double finalFontSize = fontSize.clamp(minFontSize, maxFontSize);

    // Calculate responsive padding
    final double paddingSize = screenSize.width * 0.02; // 2% of screen width
    final double minPadding = 8.0;
    final double maxPadding = 16.0;
    final double finalPadding = paddingSize.clamp(minPadding, maxPadding);

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
            borderRadius: BorderRadius.circular(finalPadding),
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
