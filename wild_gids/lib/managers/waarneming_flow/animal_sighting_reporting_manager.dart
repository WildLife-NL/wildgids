import 'package:flutter/material.dart';
import 'package:wildrapport/interfaces/waarneming_flow/animal_interface.dart';
import 'package:wildrapport/interfaces/waarneming_flow/animal_sighting_reporting_interface.dart';
import 'package:wildrapport/models/animal_waarneming_models/animal_gender_view_count_model.dart';
import 'package:wildrapport/models/animal_waarneming_models/animal_sighting_model.dart';
import 'package:wildrapport/models/animal_waarneming_models/observed_animal_entry.dart';
import 'package:wildrapport/models/ui_models/date_time_model.dart';
import 'package:wildrapport/models/enums/animal_category.dart';
import 'package:wildrapport/models/animal_waarneming_models/animal_model.dart';
import 'package:wildrapport/models/enums/animal_condition.dart';
import 'package:wildrapport/models/enums/animal_gender.dart';
import 'package:wildrapport/models/enums/animal_age.dart';
import 'package:wildrapport/models/beta_models/location_model.dart';
import 'package:wildrapport/models/animal_waarneming_models/view_count_model.dart';

class AnimalSightingReportingManager implements AnimalSightingReportingInterface {
  final List<VoidCallback> _listeners = [];
  AnimalSightingModel? _currentanimalSighting;
  final List<ObservedAnimalEntry> _observedAnimals = [];

  // Core update method
  AnimalSightingModel _updateSighting({
    List<AnimalModel>? animals,
    AnimalModel? animalSelected,
    AnimalCategory? category,
    String? description,
    List<LocationModel>? locations,
    DateTimeModel? dateTime,
    dynamic images,
    bool logChanges = false,
    String logPrefix = '',
  }) {
    _currentanimalSighting ??= createanimalSighting();

    if (logChanges) {
      debugPrint(
        '$logPrefix Previous state: ${_currentanimalSighting?.toJson()}',
      );
    }

    _currentanimalSighting = AnimalSightingModel(
      animals: animals ?? _currentanimalSighting!.animals ?? [],
      animalSelected: animalSelected ?? _currentanimalSighting!.animalSelected,
      category: category ?? _currentanimalSighting!.category,
      description: description ?? _currentanimalSighting!.description,
      locations: locations ?? _currentanimalSighting!.locations ?? [],
      dateTime: dateTime ?? _currentanimalSighting!.dateTime,
      images: images ?? _currentanimalSighting!.images,
    );

    if (logChanges) {
      debugPrint('$logPrefix New state: ${_currentanimalSighting!.toJson()}');
    }

    _notifyListeners();
    return _currentanimalSighting!;
  }

  // Helper to create animal model with preserved properties
  AnimalModel _createAnimalModel({
    required AnimalModel source,
    String? animalId,
    String? animalImagePath,
    String? animalName,
    List<AnimalGenderViewCount>? genderViewCounts,
    AnimalAge? age,
  }) {
    return AnimalModel(
      animalId: animalId ?? source.animalId,
      animalImagePath: animalImagePath ?? source.animalImagePath,
      animalName: animalName ?? source.animalName,
      genderViewCounts: genderViewCounts ?? source.genderViewCounts,
      condition: source.condition,
      age: age ?? source.age,
    );
  }

  // Helper to validate current sighting exists
  void _validateCurrentSighting() {
    if (_currentanimalSighting == null) {
      throw StateError('No current animalSighting found');
    }
  }

  // Helper to validate current animal exists
  void _validateCurrentAnimal() {
    _validateCurrentSighting();
    if (_currentanimalSighting!.animalSelected == null) {
      throw StateError('No animal found in current animalSighting');
    }
  }

@override
AnimalSightingModel createanimalSighting() {
  _currentanimalSighting = AnimalSightingModel(
    animals: [],
    animalSelected: null,
    category: null,
    description: null,
    locations: [],
    dateTime: null,
    images: null,
  );

  // NEW: reset the counted animal batches when starting a new sighting
  _observedAnimals.clear();

  _notifyListeners();
  return _currentanimalSighting!;
}


  @override
  AnimalSightingModel updateSelectedAnimal(AnimalModel selectedAnimal) {
    final updatedAnimal = _createAnimalModel(source: selectedAnimal);

    return _updateSighting(
      animalSelected: updatedAnimal,
      logChanges: true,
      logPrefix: '[animalSightingManager] Updating selected animal. ',
    );
  }

  AnimalSightingModel updateCondition(AnimalCondition condition) {
    _currentanimalSighting ??= createanimalSighting();

    final currentAnimal =
        _currentanimalSighting!.animalSelected ??
        AnimalModel(
          animalId: null,
          animalImagePath: null,
          animalName: '',
          genderViewCounts: [],
          condition: condition,
        );

    final updatedAnimal = _createAnimalModel(source: currentAnimal);

    return _updateSighting(animalSelected: updatedAnimal);
  }

  @override
  AnimalSightingModel updateGender(AnimalGender gender) {
    _validateCurrentAnimal();
    final currentAnimal = _currentanimalSighting!.animalSelected!;

    final existingAnimal = _currentanimalSighting!.animals?.firstWhere(
      (a) => a.genderViewCounts.any((gvc) => gvc.gender == gender),
      orElse:
          () => _createAnimalModel(source: currentAnimal, genderViewCounts: []),
    );

    final genderViewCounts =
        existingAnimal?.genderViewCounts ??
        [AnimalGenderViewCount(gender: gender, viewCount: ViewCountModel())];

    final updatedAnimal = _createAnimalModel(
      source: currentAnimal,
      genderViewCounts: genderViewCounts,
    );

    return _updateSighting(animalSelected: updatedAnimal);
  }

  @override
  AnimalSightingModel updateAge(AnimalAge age) {
    _validateCurrentAnimal();
    final currentAnimal = _currentanimalSighting!.animalSelected!;

    final updatedAnimal = _createAnimalModel(
      source: currentAnimal,
      age: age,
    );

    return _updateSighting(
      animalSelected: updatedAnimal,
    );
  }

  @override
  AnimalSightingModel updateViewCount(ViewCountModel viewCount) {
    _validateCurrentAnimal();
    return _updateSighting(
      animalSelected: _currentanimalSighting!.animalSelected,
    );
  }

  @override
  AnimalSightingModel updateCategory(AnimalCategory category) {
    _validateCurrentSighting();
    return _updateSighting(
      category: category,
      logChanges: true,
      logPrefix: '[AnimalSightingManager] Updating category. ',
    );
  }

  @override
  AnimalSightingModel finalizeAnimal({bool clearSelected = true}) {
    _validateCurrentAnimal();

    final currentAnimals = List<AnimalModel>.from(
      _currentanimalSighting!.animals ?? [],
    );
    currentAnimals.add(_currentanimalSighting!.animalSelected!);

    return _updateSighting(
      animals: currentAnimals,
      animalSelected:
          clearSelected ? null : _currentanimalSighting!.animalSelected,
    );
  }

  @override
  AnimalSightingModel updateDescription(String description) {
    _validateCurrentSighting();
    return _updateSighting(description: description);
  }

  @override
  AnimalSightingModel? getCurrentanimalSighting() => _currentanimalSighting;

  @override
  void addListener(VoidCallback listener) => _listeners.add(listener);

  @override
  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  @override
  void clearCurrentanimalSighting() {
    final greenLog = '\x1B[32m';
    final resetLog = '\x1B[0m';

    debugPrint(
      '$greenLog[AnimalSightingReportingManager] Current state before clearing: ${_currentanimalSighting?.toJson()}$resetLog',
    );
    _currentanimalSighting = null;
    debugPrint(
      '$greenLog[AnimalSightingReportingManager] State after clearing: $_currentanimalSighting$resetLog',
    );

    _notifyListeners();
  }

  @override
  bool validateActiveAnimalSighting() {
    if (_currentanimalSighting == null) {
      debugPrint('[AnimalSightingManager] No active animal sighting found');
      return false;
    }
    return true;
  }

  @override
  AnimalSightingModel processAnimalSelection(
    AnimalModel selectedAnimal,
    AnimalManagerInterface animalManager,
  ) {
    return updateSelectedAnimal(
      animalManager.handleAnimalSelection(selectedAnimal),
    );
  }

  @override
  bool handleGenderSelection(AnimalGender selectedGender) {
    final orangeLog = '\x1B[38;5;208m';
    final resetLog = '\x1B[0m';

    debugPrint(
      '$orangeLog[AnimalSightingManager] Handling gender selection: $selectedGender$resetLog',
    );

    try {
      updateGender(selectedGender);
      debugPrint('[AnimalSightingManager] Successfully updated gender');
      return true;
    } catch (e) {
      debugPrint('[AnimalSightingManager] Failed to update gender: $e');
      return false;
    }
  }

  @override
  AnimalSightingModel updateAnimal(AnimalModel animalToUpdate) {
    _validateCurrentSighting();

    debugPrint(
      '[AnimalSightingManager] Updating animal: {id: ${animalToUpdate.animalId}, name: ${animalToUpdate.animalName}}',
    );

    List<AnimalModel> updatedAnimals = List.from(
      _currentanimalSighting!.animals ?? [],
    );
    final existingIndex = updatedAnimals.indexWhere(
      (a) => a.animalId == animalToUpdate.animalId,
    );

    if (existingIndex != -1) {
      debugPrint(
        '[AnimalSightingManager] Updating existing animal at index: $existingIndex',
      );
      updatedAnimals[existingIndex] = animalToUpdate;
    } else {
      debugPrint('[AnimalSightingManager] Adding new animal to the list');
      updatedAnimals.add(animalToUpdate);
    }

    return _updateSighting(
      animals: updatedAnimals,
      animalSelected: animalToUpdate,
      logChanges: true,
      logPrefix: '[AnimalSightingManager] Updated sighting state: ',
    );
  }

  AnimalSightingModel updateAnimalData(
    String animalName,
    AnimalGender gender, {
    ViewCountModel? viewCount,
    AnimalCondition? condition,
    String? description,
  }) {
    _validateCurrentSighting();

    final updatedAnimals = List<AnimalModel>.from(
      _currentanimalSighting!.animals ?? [],
    );
    final animalIndex = updatedAnimals.indexWhere(
      (animal) =>
          animal.animalName == animalName &&
          animal.genderViewCounts.any((gvc) => gvc.gender == gender),
    );

    if (animalIndex != -1) {
      final currentAnimal = updatedAnimals[animalIndex];
      updatedAnimals[animalIndex] = _createAnimalModel(
        source: currentAnimal,
        genderViewCounts:
            viewCount != null
                ? [AnimalGenderViewCount(gender: gender, viewCount: viewCount)]
                : currentAnimal.genderViewCounts,
      );
    }

    return _updateSighting(
      animals: updatedAnimals,
      description: description ?? _currentanimalSighting!.description ?? '',
      logChanges: true,
      logPrefix: '[AnimalSightingManager] Updated sighting with description: ',
    );
  }

  @override
  AnimalSightingModel updateLocation(LocationModel location) {
    List<LocationModel> updatedLocations = List.from(
      _currentanimalSighting?.locations ?? [],
    );
    updatedLocations.add(location);
    return _updateSighting(locations: updatedLocations);
  }

  @override
  AnimalSightingModel removeLocation(LocationModel location) {
    List<LocationModel> updatedLocations = List.from(
      _currentanimalSighting?.locations ?? [],
    );
    updatedLocations.removeWhere((loc) => loc.source == location.source);
    return _updateSighting(locations: updatedLocations);
  }

  @override
  AnimalSightingModel updateDateTimeModel(DateTimeModel dateTimeModel) {
    return _updateSighting(
      dateTime: dateTimeModel,
      logChanges: true,
      logPrefix: '[AnimalSightingManager] Updating datetime model. ',
    );
  }

  @override
  AnimalSightingModel updateDateTime(DateTime dateTime) {
    return updateDateTimeModel(
      DateTimeModel(dateTime: dateTime, isUnknown: false),
    );
  }

  @override
  AnimalCategory convertStringToCategory(String status) {
    switch (status) {
      case 'Evenhoevigen':
        return AnimalCategory.evenhoevigen;
      case 'Knaagdieren':
        return AnimalCategory.knaagdieren;
      case 'Roofdieren':
        return AnimalCategory.roofdieren;
      case 'Andere':
        return AnimalCategory.andere;
      default:
        debugPrint(
          '[AnimalSightingManager] Unknown category: $status, defaulting to andere',
        );
        return AnimalCategory.andere;
    }
  }

@override
void addObservedAnimal(ObservedAnimalEntry entry) {
  _observedAnimals.add(entry);
  _notifyListeners(); // trigger rebuilds for listeners (tables etc.)
}

@override
List<ObservedAnimalEntry> getObservedAnimals() {
  return List.unmodifiable(_observedAnimals);
}

  @override
  void syncObservedAnimalsToSighting() {
    // We need a sighting to sync into
    if (_currentanimalSighting == null) return;

    // We also need to know which species was selected
    final baseAnimal = _currentanimalSighting!.animalSelected;
    if (baseAnimal == null) return;

    // Build a legacy-style `animals` list that SightingApiTransformer understands
    final List<AnimalModel> converted = [];

    for (final entry in _observedAnimals) {
      // Create a ViewCountModel where only the matching age bucket is filled
      final vc = ViewCountModel(
        pasGeborenAmount:
            entry.age == AnimalAge.pasGeboren ? entry.count : 0,
        onvolwassenAmount:
            entry.age == AnimalAge.onvolwassen ? entry.count : 0,
        volwassenAmount:
            entry.age == AnimalAge.volwassen ? entry.count : 0,
        unknownAmount:
            entry.age == AnimalAge.onbekend ? entry.count : 0,
      );

      // Attach gender + the age bucket counts
      final gvc = AnimalGenderViewCount(
        gender: entry.gender,
        viewCount: vc,
      );

      // Build one AnimalModel for this batch
      final batchModel = AnimalModel(
        animalId: baseAnimal.animalId,
        animalImagePath: baseAnimal.animalImagePath,
        animalName: baseAnimal.animalName,
        condition: entry.condition,
        genderViewCounts: [gvc],
        age: entry.age,
      );

      converted.add(batchModel);
    }

    // Write that into the active sighting
    _currentanimalSighting = _currentanimalSighting!.copyWith(
      animals: converted,
    );

    _notifyListeners();
  }



}
