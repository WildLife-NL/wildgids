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
          backgroundColor: AppColors.offWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 4,
          foregroundColor: Colors.black.withValues(alpha: 0.1),
        ),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            color: AppColors.offWhite,
          ),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: Container(
                    width: double.infinity,
                    color: AppColors.offWhite,
                    child:
                        animal.animalImagePath != null
                            ? Image(
                              image: AssetImage(animal.animalImagePath!),
                              fit: BoxFit.cover,
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
                    color: AppColors.brown,
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
