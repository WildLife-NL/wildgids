import 'package:flutter/material.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_model.dart';
import 'package:wildgids/widgets/animals/animal_tile.dart';

class AnimalGrid extends StatelessWidget {
  final List<AnimalModel> animals;
  final Function(AnimalModel) onAnimalSelected;
  final Set<String> selectedAnimalIds;
  final Map<String, int> selectedOrderIds;

  const AnimalGrid({
    super.key,
    required this.animals,
    required this.onAnimalSelected,
    this.selectedAnimalIds = const {},
    this.selectedOrderIds = const {},
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column
        Expanded(
          child: _buildColumn(
            itemCount: (animals.length + 1) ~/ 2,
            builder: (index) {
              final animal = animals[index * 2];
              return _buildSquareTile(
                animal: animal,
                onTap: () => onAnimalSelected(animal),
                isSelected: selectedAnimalIds.contains(animal.animalId),
                selectionNumber: selectedOrderIds[animal.animalId],
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        // Right Column
        Expanded(
          child: _buildColumn(
            itemCount: animals.length ~/ 2,
            builder: (index) {
              final animal = animals[index * 2 + 1];
              return _buildSquareTile(
                animal: animal,
                onTap: () => onAnimalSelected(animal),
                isSelected: selectedAnimalIds.contains(animal.animalId),
                selectionNumber: selectedOrderIds[animal.animalId],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildColumn({
    required int itemCount,
    required Widget Function(int index) builder,
  }) {
    const rowSpacing = 16.0;

    return Column(
      children: List.generate(itemCount, (index) {
        final tile = builder(index);
        if (index == itemCount - 1) return tile;
        return Padding(
          padding: const EdgeInsets.only(bottom: rowSpacing),
          child: tile,
        );
      }),
    );
  }

  Widget _buildSquareTile({
    required AnimalModel animal,
    required VoidCallback onTap,
    required bool isSelected,
    int? selectionNumber,
  }) {
    return SizedBox(
      width: double.infinity,
      child: AspectRatio(
        aspectRatio: 1,
        child: AnimalTile(
          animal: animal,
          onTap: onTap,
          isSelected: isSelected,
          selectionNumber: selectionNumber,
        ),
      ),
    );
  }
}

