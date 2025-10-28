import 'package:wildrapport/models/animal_waarneming_models/animal_model.dart';
import 'package:wildrapport/models/enums/animal_category.dart';

abstract class AnimalRepositoryInterface {
  Future<List<AnimalModel>> getAnimals();
}

abstract class AnimalSelectionInterface {
  AnimalModel handleAnimalSelection(AnimalModel selectedAnimal);
}

abstract class AnimalManagerInterface {
  Future<List<AnimalModel>> getAnimals();
  AnimalModel handleAnimalSelection(AnimalModel selectedAnimal);
  String getSelectedFilter();
  void updateFilter(String filter);
  void updateSearchTerm(String searchTerm);
  void addListener(Function() listener);
  void removeListener(Function() listener);
  Future<List<AnimalModel>> getAnimalsByCategory({AnimalCategory? category});
}

