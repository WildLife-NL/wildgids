import 'package:wildrapport/models/ui_models/brown_button_model.dart';
import 'package:wildrapport/models/animal_waarneming_models/animal_model.dart';

abstract class CategoryInterface {
  List<Map<String, String>> getAnimalCategories();
}

abstract class FilterInterface {
  List<T> filterByCategory<T>(
    List<T> items,
    String category,
    bool Function(T item, String category) filterFunction,
  );

  List<BrownButtonModel> getAvailableFilters(String currentFilter);

  List<AnimalModel> filterAnimalsAlphabetically(List<AnimalModel> animals);

  List<AnimalModel> searchAnimals(List<AnimalModel> animals, String searchTerm);
}
