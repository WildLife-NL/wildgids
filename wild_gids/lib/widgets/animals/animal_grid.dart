import 'package:flutter/material.dart';
import 'package:wildrapport/models/animal_waarneming_models/animal_model.dart';
import 'package:wildrapport/widgets/animals/animal_tile.dart';

class AnimalGrid extends StatelessWidget {
  final List<AnimalModel> animals;
  final Function(AnimalModel) onAnimalSelected;

  const AnimalGrid({
    super.key,
    required this.animals,
    required this.onAnimalSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column
        Expanded(
          child: Column(
            children: List.generate(
              (animals.length + 1) ~/ 2,
              (index) => SizedBox(
                height: MediaQuery.of(context).size.height * 0.4,
                child: AnimalTile(
                  animal: animals[index * 2],
                  onTap: () => onAnimalSelected(animals[index * 2]),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Right Column
        Expanded(
          child: Column(
            children: List.generate(
              animals.length ~/ 2,
              (index) => SizedBox(
                height: MediaQuery.of(context).size.height * 0.4,
                child: AnimalTile(
                  animal: animals[index * 2 + 1],
                  onTap: () => onAnimalSelected(animals[index * 2 + 1]),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
