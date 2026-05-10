import 'package:flutter/material.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_pin.dart';
import 'package:wildgids/models/api_models/interaction_query_result.dart';
import 'package:wildgids/widgets/map/animal_detail_card.dart';

class InteractionDetailDialog extends StatelessWidget {
  final InteractionQueryResult interaction;
  final String? animalIconPath;

  const InteractionDetailDialog({
    super.key,
    required this.interaction,
    this.animalIconPath,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom + 78;

    final interactionAsPin = AnimalPin(
      id: interaction.id,
      lat: interaction.lat,
      lon: interaction.lon,
      seenAt: interaction.moment,
      speciesName: interaction.speciesName,
    );

    return Dialog(
      alignment: Alignment.bottomCenter,
      insetPadding: EdgeInsets.fromLTRB(8, 24, 8, bottomInset),
      child: Stack(
        children: [
          AnimalDetailCard(
            animal: interactionAsPin,
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
