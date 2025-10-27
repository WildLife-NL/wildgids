import 'package:flutter/foundation.dart';
import 'package:widgets/interfaces/waarneming_flow/animal_interface.dart';
import 'package:widgets/models/animal_waarneming_models/animal_model.dart';
import 'package:widgets/interfaces/data_apis/species_api_interface.dart';
import 'package:widgets/interfaces/other/filter_interface.dart';
import 'package:widgets/models/enums/animal_category.dart';
import 'package:widgets/models/enums/filter_type.dart';



class AnimalManager
    implements
        AnimalRepositoryInterface,
        AnimalSelectionInterface,
        AnimalManagerInterface {
  final _listeners = <Function()>[];
  String _selectedFilter = 'Filteren';
  final SpeciesApiInterface _speciesApi;
  final FilterInterface _filterManager;
  List<AnimalModel>? _cachedAnimals;
  String? _currentSearchTerm;

  AnimalManager(this._speciesApi, this._filterManager);

  @override
  Future<List<AnimalModel>> getAnimals({AnimalCategory? category}) async {

    try {
      if (_cachedAnimals != null) {
        return _getFilteredAnimals(_cachedAnimals!);
      }

      final species = await _speciesApi.getAllSpecies();
      _cachedAnimals =
          species
              .map(
                (s) => AnimalModel(
                  animalId: s.id, // Added animalId from species
                  animalImagePath: 'assets/wolf.png',
                  animalName: s.commonName,
                  genderViewCounts: [], // Initialize with empty list
                ),
              )
              .toList();

      // Add the "Unknown" option with no image
      _cachedAnimals!.add(
        AnimalModel(
          animalId: 'unknown', // Added default ID for unknown
          animalImagePath: null,
          animalName: 'Onbekend',
          genderViewCounts: [], // Initialize with empty list
        ),
      );

      return _getFilteredAnimals(_cachedAnimals!);
    } catch (e) {
      debugPrint('[AnimalManager] Error fetching animals: $e');
      return [];
    }
  }

  List<AnimalModel> _getFilteredAnimals(List<AnimalModel> animals) {
    if (_currentSearchTerm?.isNotEmpty == true) {
      // Apply search if there's a search term, regardless of filter
      return _filterManager.searchAnimals(animals, _currentSearchTerm!);
    }

    if (_selectedFilter == FilterType.alphabetical.displayText) {
      return _filterManager.filterAnimalsAlphabetically(animals);
    } else if (_selectedFilter == FilterType.mostViewed.displayText) {
      // Temporarily disabled - return unfiltered list
      return animals;
    }

    return animals;
  }

  @override
  AnimalModel handleAnimalSelection(AnimalModel selectedAnimal) {
    debugPrint('Selected animal: ${selectedAnimal.animalName}');
    return selectedAnimal;
  }

  @override
  String getSelectedFilter() => _selectedFilter;

  @override
  void updateFilter(String filter) {
    _selectedFilter = filter;
    _notifyListeners();
  }

  @override
  void updateSearchTerm(String searchTerm) {
    _currentSearchTerm = searchTerm;
    _notifyListeners(); // Make sure this is called to trigger UI updates
  }

  @override
  void addListener(Function() listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(Function() listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

@override
Future<List<AnimalModel>> getAnimalsByCategory({AnimalCategory? category}) async {
  final animals = await getAnimals();
  if (category == null) return animals;

  return animals.where((a) {
    final name = a.animalName.toLowerCase();

    switch (category) {
      case AnimalCategory.evenhoevigen:
        return name.contains('ree') || name.contains('hert') || name.contains('zwijn');
      case AnimalCategory.knaagdieren:
        return name.contains('bever') || name.contains('rat') || name.contains('muis');
      case AnimalCategory.roofdieren:
        return name.contains('vos') || name.contains('wolf') || name.contains('das');
      case AnimalCategory.andere:
        return true;
    }
  }).toList();
}


}
