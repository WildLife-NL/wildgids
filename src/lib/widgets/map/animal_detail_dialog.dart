import 'package:flutter/material.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_pin.dart';
import 'package:wildgids/widgets/map/animal_detail_card.dart';

class AnimalDetailDialog extends StatelessWidget {
  final AnimalPin? animal;
  final String? animalIconPath;

  const AnimalDetailDialog({
    super.key,
    required this.animal,
    this.animalIconPath,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom + 78;

    return Dialog(
      alignment: Alignment.bottomCenter,
      insetPadding: EdgeInsets.fromLTRB(8, 24, 8, bottomInset),
      child: Stack(
        children: [
          AnimalDetailCard(
            animal: animal,
            iconPath: animalIconPath,
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              splashRadius: 20,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
