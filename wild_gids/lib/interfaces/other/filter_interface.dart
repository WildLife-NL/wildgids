import 'package:widgets/models/enums/filter_type.dart';
import 'package:widgets/models/animal_waarneming_models/animal_model.dart';

abstract class FilterInterface {
  /// Gets the currently selected filter
  String getSelectedFilter();
  
  /// Updates the filter
  void updateFilter(String filter);
  
  /// Gets the current filter type
  FilterType getFilterType();
  
  /// Filters animals alphabetically
  List<AnimalModel> filterAnimalsAlphabetically(List<AnimalModel> animals);
  
  /// Searches animals by name
  List<AnimalModel> searchAnimals(List<AnimalModel> animals, String searchTerm);
  
  /// Adds a listener for filter changes
  void addListener(Function() listener);
  
  /// Removes a listener
  void removeListener(Function() listener);
}
