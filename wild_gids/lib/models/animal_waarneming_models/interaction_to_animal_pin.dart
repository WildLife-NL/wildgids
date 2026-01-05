import 'package:wildrapport/models/animal_waarneming_models/animal_pin.dart';
import 'package:wildrapport/models/api_models/interaction_query_result.dart';

extension InteractionToAnimalPin on InteractionQueryResult {
  AnimalPin toAnimalPin() {
    return AnimalPin(
      id: id,
      lat: lat,
      lon: lon,
      seenAt: moment,
      speciesName: speciesName ?? typeName,
    );
  }
}
