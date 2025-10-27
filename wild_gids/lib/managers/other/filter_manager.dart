import 'package:flutter/foundation.dart';
import 'package:widgets/interfaces/other/filter_interface.dart';
import 'package:widgets/models/enums/filter_type.dart';
import 'package:widgets/models/animal_waarneming_models/animal_model.dart';

class FilterManager extends ChangeNotifier implements FilterInterface {
  String _selectedFilter = 'Filteren';
  final _listeners = <Function()>[];

  @override
  String getSelectedFilter() => _selectedFilter;

  @override
  void updateFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
    for (var listener in _listeners) {
      listener();
    }
  }

  @override
  FilterType getFilterType() {
    if (_selectedFilter == FilterType.alphabetical.displayText) {
      return FilterType.alphabetical;
    } else if (_selectedFilter == FilterType.mostViewed.displayText) {
      return FilterType.mostViewed;
    }
    return FilterType.alphabetical; // Default
  }

  @override
  List<AnimalModel> filterAnimalsAlphabetically(List<AnimalModel> animals) {
    final sorted = List<AnimalModel>.from(animals);
    sorted.sort((a, b) => a.animalName.compareTo(b.animalName));
    return sorted;
  }

  @override
  List<AnimalModel> searchAnimals(List<AnimalModel> animals, String searchTerm) {
    final lowerSearch = searchTerm.toLowerCase();
    return animals
        .where((animal) =>
            animal.animalName.toLowerCase().contains(lowerSearch))
        .toList();
  }

  @override
  void addListener(Function() listener) {
    _listeners.add(listener);
    super.addListener(listener);
  }

  @override
  void removeListener(Function() listener) {
    _listeners.remove(listener);
    super.removeListener(listener);
  }
}
