import 'package:flutter/foundation.dart';
import 'package:wildrapport/interfaces/waarneming_flow/animal_interface.dart';
import 'package:wildrapport/models/animal_waarneming_models/animal_model.dart';
import 'package:wildrapport/interfaces/data_apis/species_api_interface.dart';
import 'package:wildrapport/interfaces/filters/filter_interface.dart';
import 'package:wildrapport/models/enums/filter_type.dart';
import 'package:wildrapport/models/enums/animal_category.dart';



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
  debugPrint('[AnimalManager] species fetched: ${species.length}');
      _cachedAnimals =
          species
              .map(
                (s) => AnimalModel(
                  animalId: s.id, // Added animalId from species
                  animalImagePath: _assetForCommonName(s.commonName),
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

  // Map a species common name to an asset path when available.
  // Returns null when no matching asset is known.
  String? _assetForCommonName(String? commonName) {
    if (commonName == null || commonName.isEmpty) return null;
    final name = commonName.toLowerCase();

    if (name.contains('wolf')) return 'assets/wolf.png';
    if (name.contains('vos')) return 'assets/vos.png';
    if (name.contains('ree')) return 'assets/ree.png';
    if (name.contains('damhert')) return 'assets/Damhert app.png';
    if (name.contains('edelhert')) return 'assets/Edelhert.png';
    if (name.contains('hert')) return 'assets/deer.png';
    if (name.contains('zwijn') || name.contains('wild zwijn')) return 'assets/Wild Zwijn.png';
    if (name.contains('bever')) return 'assets/Bever.png';
    if (name.contains('eekhoorn')) return 'assets/eekhoorn.png';
    if (name.contains('konijn') || name.contains('konijn')) return 'assets/konijn.png';
    if (name.contains('haas')) return 'assets/haas.png';
    if (name.contains('otter')) return 'assets/otter.png';
    if (name.contains('das')) return 'assets/Das.png';
    if (name.contains('marter') || name.contains('steenmarter') || name.contains('marten')) return 'assets/steenmarter.png';
    if (name.contains('bunzing') || name.contains('wezel') || name.contains('wezel')) return 'assets/Bunzing.png';
    if (name.contains('wolfkat') || name.contains('wilde kat') || name.contains('wilde')) return 'assets/wilde kat.png';
    if (name.contains('tiger') || name.contains('tijger')) return 'assets/tiger.png';
    if (name.contains('beer')) return 'assets/beer.png';
    if (name.contains('otter')) return 'assets/otter.png';
    if (name.contains('konik') || name.contains('konikpaard')) return 'assets/Konikpaard.png';
    if (name.contains('pony') || name.contains('shetland')) return 'assets/Shetland pony.png';
    if (name.contains('galloway')) return 'assets/Galloway.png';
    if (name.contains('wisent') || name.contains('wisent')) return 'assets/Wisent App.png';
    if (name.contains('tauros')) return 'assets/Tauros app.png';

    // Fallbacks for common small mammals
    if (name.contains('egel')) return 'assets/egel.png';
    if (name.contains('wezel')) return 'assets/wezel.png';
    if (name.contains('hermelijn')) return 'assets/Hermelijn.png';
    if (name.contains('otter')) return 'assets/otter.png';

    // No known matching asset
    return null;
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
  debugPrint('[AnimalManager] getAnimalsByCategory called with category: $category; total animals fetched: ${animals.length}');
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
