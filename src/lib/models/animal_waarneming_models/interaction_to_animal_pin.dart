import 'package:wildgids/models/animal_waarneming_models/animal_pin.dart';
import 'package:wildgids/models/api_models/interaction_query_result.dart';

extension InteractionToAnimalPin on InteractionQueryResult {
  AnimalPin toAnimalPin() {
    final count = involvedAnimals?.length;

    return AnimalPin(
      id: id,
      lat: lat,
      lon: lon,
      seenAt: moment,
      speciesName: speciesName ?? typeName,
      speciesLatinName: speciesLatinName,
      locationLabel: placeName,
      reportedByName: userName,
      animalCount: count,
      involvedAnimals: involvedAnimals
          ?.map(
            (a) => AnimalObservedDetail(
              sex: a.sex,
              lifeStage: a.lifeStage,
              condition: a.condition,
            ),
          )
          .toList(),
      groupSummary: count != null && count > 0
          ? '$count ${count == 1 ? 'dier' : 'dieren'}'
          : null,
      reportType: 'waarneming',
    );
  }
}