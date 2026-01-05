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
        return _getFilteredAnimals(_cachedAnimals!);
      }

      final species = await _speciesApi.getAllSpecies();
      debugPrint('[AnimalManager] species fetched: ${species.length}');
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

      return _getFilteredAnimals(_cachedAnimals!);
    } catch (e) {
      debugPrint('[AnimalManager] Error fetching animals: $e');
      return [];
    }
  }

  // Map a species common name to a photo in assets/animals when available.
  // Returns null when no matching asset is known.
  String? _assetForCommonName(String? commonName) {
    if (commonName == null || commonName.isEmpty) return null;
    final name = commonName.toLowerCase();

    // Use curated animal photos under assets/animals
    if (name.contains('wolf')) return 'assets/animals/wolf.png';
    if (name.contains('vos') || name.contains('fox')) return 'assets/animals/vos.png';
    if (name.contains('das') || name.contains('badger')) return 'assets/animals/das.png';
    if (name.contains('ree') || name.contains('roe deer') || name.contains('deer')) return 'assets/animals/ree.png';
    if (name.contains('damhert') || name.contains('fallow')) return 'assets/animals/damhert.png';
    if (name.contains('edelhert') || name.contains('red deer')) return 'assets/animals/edelhert.png';
    if (name.contains('hert')) return 'assets/animals/edelhert.png';
    if (name.contains('zwijn') || name.contains('wild zwijn') || name.contains('boar'))
      return 'assets/animals/wild zwijn.png';
    if (name.contains('bever') || name.contains('beaver')) return 'assets/animals/bever.png';
    if (name.contains('eekhoorn') || name.contains('squirrel')) return 'assets/animals/eekhoorn.png';
    if (name.contains('egel') || name.contains('hedgehog')) return 'assets/animals/egel.png';
    if (name.contains('steenmarter')) return 'assets/animals/steenmarter.png';
    if (name.contains('boommarter')) return 'assets/animals/boommarter.png';
    if (name.contains('marter') || name.contains('marten')) return 'assets/animals/steenmarter.png';
    if (name.contains('bunzing')) return 'assets/animals/bunzing.png';
    if (name.contains('wezel') || name.contains('weasel')) return 'assets/animals/wezel.png';
    if (name.contains('hermelijn') || name.contains('stoat')) return 'assets/animals/hermelijn.png';
    if (name.contains('otter')) return 'assets/animals/otter.png';
    if (name.contains('wild kat') || name.contains('wilde kat') || name.contains('wildcat')) return 'assets/animals/wild kat.png';
    if (name.contains('wisent') || name.contains('bison')) return 'assets/animals/wisent.png';
    if (name.contains('hooglander') || name.contains('highlander')) return 'assets/animals/hooglander.png';
    if (name.contains('galloway')) return 'assets/animals/galloway.png';
    if (name.contains('konik') || name.contains('konikpaard')) return 'assets/animals/konikpaard.png';
    if (name.contains('shetland') || name.contains('pony')) return 'assets/animals/shetland pony.png';
    if (name.contains('exmoor')) return 'assets/animals/exmoor pony.png';
    if (name.contains('tauros')) return 'assets/animals/tauros.png';
    if (name.contains('europese nerts') || name.contains('european mink')) return 'assets/animals/europese nerts.png';
    if (name.contains('woelrat') || name.contains('vole')) return 'assets/animals/woelrat.png';
    if (name.contains('goudjakhals') || name.contains('golden jackal')) return 'assets/animals/goudjakhals.png';
    if (name.contains('haas') || name.contains('hare')) return 'assets/animals/haas.png';
    if (name.contains('konijn') || name.contains('rabbit')) return 'assets/animals/konijn.png';

    // No matching icon available in animals folder
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
  Future<List<String>> getBackendCategories() async {
    // Prefer cached animals to avoid extra API call
    final animals = _cachedAnimals ?? await getAnimals();
    final set = <String>{};
    for (final a in animals) {
      final c = a.category?.trim();
      if (c != null && c.isNotEmpty) set.add(c);
    }
    final list = set.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    debugPrint('[AnimalManager] categories fetched: ${list.length}');
    return list;
  }

  /// Filter animals by a backend-provided category name. Null or empty returns all.
  Future<List<AnimalModel>> getAnimalsByBackendCategory({String? category}) async {
    final animals = await getAnimals();
    if (category == null || category.isEmpty || category == 'Alle') return animals;
    return animals.where((a) => (a.category ?? '').toLowerCase() == category.toLowerCase()).toList();
  }
}
