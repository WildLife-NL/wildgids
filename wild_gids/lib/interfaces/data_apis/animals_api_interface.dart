import 'package:wildrapport/models/animal_waarneming_models/animal_pin.dart';

abstract class AnimalsApiInterface {
  Future<List<AnimalPin>> getAllAnimals();
}
