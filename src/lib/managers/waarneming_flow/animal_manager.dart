import 'package:flutter/foundation.dart';
import 'package:wildgids/interfaces/waarneming_flow/animal_interface.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_model.dart';
import 'package:wildgids/interfaces/data_apis/species_api_interface.dart';
import 'package:wildgids/interfaces/filters/filter_interface.dart';
import 'package:wildgids/models/enums/filter_type.dart';
import 'package:wildgids/models/enums/animal_category.dart';
import 'package:wildgids/utils/species_image_resolver.dart';

class AnimalManager
    implements
        AnimalRepositoryInterface,
        AnimalSelectionInterface,
        AnimalManagerInterface {
  final _listeners = <Function()>[];
  String _selectedFilter = FilterType.alphabetical.displayText;
  final SpeciesApiInterface _speciesApi;
  final FilterInterface _filterManager;
  List<AnimalModel>? _cachedAnimals;
  String? _currentSearchTerm;

  AnimalManager(this._speciesApi, this._filterManager);

  @override
  Future<List<AnimalModel>> getAnimals({AnimalCategory? category}) async {
    try {
      if (_cachedAnimals != null) {
        debugPrint('[AnimalManager] Returning cached animals: ${_cachedAnimals!.length}');
        return _getFilteredAnimals(_cachedAnimals!);
      }

      debugPrint('[AnimalManager] Fetching fresh species from API...');
      final species = await _speciesApi.getAllSpecies();
      debugPrint('[AnimalManager] Raw species fetched: ${species.length}');
      
      if (species.isEmpty) {
        debugPrint('[AnimalManager] WARNING: API returned empty species list');
      } else {
        debugPrint('[AnimalManager] Sample species: ${species.take(3).map((s) => '${s.commonName} (${s.id})').join(", ")}');
      }
      
      _cachedAnimals = species
          .map(
            (s) => AnimalModel(
              animalId: s.id,
              animalImagePath: _assetForCommonName(s.commonName),
              animalName: s.commonName,
              category: s.category,
              genderViewCounts: [],
            ),
          )
          .toList();

      debugPrint('[AnimalManager] Converted to ${_cachedAnimals!.length} AnimalModels');
      return _getFilteredAnimals(_cachedAnimals!);
    } catch (e, stackTrace) {
      debugPrint('[AnimalManager] ERROR in getAnimals(): $e');
      debugPrint('[AnimalManager] Stack trace: $stackTrace');
      return [];
    }
  }

  // Always resolve to color-animal assets.
  String? _assetForCommonName(String? commonName) {
    return SpeciesImageResolver.drawingForCommonName(commonName);
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
  Future<List<AnimalModel>> getAnimalsByCategory({
    AnimalCategory? category,
  }) async {
    final animals = await getAnimals();
    debugPrint('[AnimalManager] getAnimalsByCategory legacy enum used: $category');
    if (category == null) return animals;
    // Legacy: keep old behavior if enum is provided
    return animals;
  }

  /// Returns unique backend categories derived from species data.
  @override
  Future<List<String>> getBackendCategories() async {
    // Prefer cached animals to avoid extra API call
    final animals = _cachedAnimals ?? await getAnimals();
    debugPrint('[AnimalManager] getBackendCategories: Processing ${animals.length} animals');
    final set = <String>{};
    for (final a in animals) {
      final c = a.category?.trim();
      if (c != null && c.isNotEmpty) {
        set.add(c);
        debugPrint('[AnimalManager] Found category: "$c" from animal: ${a.animalName}');
      }
    }
    final list = set.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    debugPrint('[AnimalManager] Final categories: $list (${list.length} unique)');
    return list;
  }

  /// Filter animals by a backend-provided category name. Null or empty returns all.
  @override
  Future<List<AnimalModel>> getAnimalsByBackendCategory({String? category}) async {
    final animals = await getAnimals();
    if (category == null || category.isEmpty || category == 'Alle') return animals;
    return animals.where((a) => (a.category ?? '').toLowerCase() == category.toLowerCase()).toList();
  }
}

