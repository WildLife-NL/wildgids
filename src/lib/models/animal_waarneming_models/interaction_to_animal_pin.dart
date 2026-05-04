import 'package:wildgids/models/animal_waarneming_models/animal_pin.dart';
import 'package:wildgids/models/api_models/interaction_query_result.dart';

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

