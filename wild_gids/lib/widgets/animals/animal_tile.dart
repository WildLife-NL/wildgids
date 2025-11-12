import 'package:flutter/material.dart';
import 'package:wildrapport/models/animal_waarneming_models/animal_model.dart';
import 'package:wildrapport/constants/app_colors.dart';

class AnimalTile extends StatelessWidget {
  final AnimalModel animal;
  final VoidCallback onTap;

  const AnimalTile({super.key, required this.animal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          // Use pure white for the button background when not tapped
          backgroundColor: AppColors.lightMintGreen100,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 0,
        ).copyWith(
          // Use the app's brown300 color for hover/pressed overlay so the
          // photo container highlights with 0xFFEBC4A6 as requested.
          overlayColor: MaterialStateProperty.resolveWith<Color?>(
            (states) {
              if (states.contains(MaterialState.hovered)) {
                return AppColors.brown300.withOpacity(0.12);
              }
              if (states.contains(MaterialState.pressed)) {
                return AppColors.brown300.withOpacity(0.18);
              }
              return null;
            },
          ),
        ),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            // Make the visible container background pure white when idle
            color: AppColors.lightMintGreen100,
          ),
          child: Column(
            children: [
              // Make image container square using AspectRatio
              AspectRatio(
                aspectRatio: 1.0, // Square ratio
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: double.infinity,
                    color: AppColors.lightMintGreen100,
                    child: animal.animalImagePath != null
                        ? Image(
                            image: AssetImage(animal.animalImagePath!),
                            fit: BoxFit.cover, // Cover to fill the square, cropping if needed
                            frameBuilder: (
                              context,
                              child,
                              frame,
                              wasSynchronouslyLoaded,
                            ) {
                              if (wasSynchronouslyLoaded) return child;
                              return AnimatedOpacity(
                                opacity: frame == null ? 0 : 1,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                                child: child,
                              );
                            },
                          )
                        : const Center(
                            child: Icon(
                              Icons.help_outline,
                              size: 80,
                              color: AppColors.brown,
                            ),
                          ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  animal.animalName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
