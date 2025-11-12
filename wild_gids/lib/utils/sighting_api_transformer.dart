import 'package:flutter/material.dart';
import 'package:wildrapport/models/animal_waarneming_models/animal_sighting_model.dart';
import 'package:wildrapport/models/beta_models/sighted_animal_model.dart';
import 'package:wildrapport/models/enums/location_source.dart';
import 'dart:convert';

class SightingApiTransformer {
  static Map<String, dynamic> transformForApi(AnimalSightingModel sighting) {
    debugPrint('=== Starting API Transform ===');
    debugPrint('Input Sighting: ${sighting.toJson()}');

    // Validate required fields
    if (sighting.locations == null || sighting.locations!.isEmpty) {
      throw StateError('Location is required for API submission');
    }
    if (sighting.dateTime == null || sighting.dateTime!.dateTime == null) {
      throw StateError('DateTime is required for API submission');
    }
    if (sighting.animals == null || sighting.animals!.isEmpty) {
      throw StateError('At least one animal is required for API submission');
    }
    if (sighting.animalSelected?.animalId == null) {
      throw StateError('Species ID is required for API submission');
    }

    // Find system and manual locations
    final systemLocation = sighting.locations!.firstWhere(
      (loc) => loc.source == LocationSource.system,
      orElse: () => throw StateError('System location is required'),
    );
    debugPrint('System Location: ${systemLocation.toJson()}');

    final manualLocation = sighting.locations!.firstWhere(
      (loc) => loc.source == LocationSource.manual,
      orElse: () => throw StateError('Manual location is required'),
    );
    debugPrint('Manual Location: ${manualLocation.toJson()}');

    // Transform animals to SightedAnimal format
    final List<SightedAnimal> sightedAnimals = [];
    for (final animal in sighting.animals!) {
      final condition = animal.condition?.toString().split('.').last ?? 'other';
      final mappedCondition = _mapCondition(condition);

      for (final genderView in animal.genderViewCounts) {
        final genderString = genderView.gender.toString().split('.').last;
        final sex = _mapSex(genderString);

        void addEntries(int amount, String ageKey) {
          if (amount > 0) {
            final age = _mapAge(ageKey);
            final lifeStage = _mapLifeStage(age);
            for (int i = 0; i < amount; i++) {
              sightedAnimals.add(
                SightedAnimal(
                  condition: mappedCondition,
                  lifeStage: lifeStage,
                  sex: sex,
                ),
              );
            }
          }
        }

        addEntries(genderView.viewCount.pasGeborenAmount, 'pasGeborenAmount');
        addEntries(genderView.viewCount.onvolwassenAmount, 'onvolwassenAmount');
        addEntries(genderView.viewCount.volwassenAmount, 'volwassenAmount');
        addEntries(genderView.viewCount.unknownAmount, 'unknownAmount');
      }
    }

    final apiPayload = {
      "description": sighting.description ?? '',
      "location": {
        "latitude": systemLocation.latitude,
        "longitude": systemLocation.longitude,
      },
      "moment":
          "${sighting.dateTime!.dateTime!.toIso8601String().split('.')[0]}+02:00",
      "place": {
        "latitude": manualLocation.latitude,
        "longitude": manualLocation.longitude,
      },
      "reportOfSighting": {
        "involvedAnimals":
            sightedAnimals.map((animal) => animal.toJson()).toList(),
      },
      "speciesID": sighting.animalSelected!.animalId,
      "typeID": 1,
    };

    debugPrint('=== Final API Payload ===');
    debugPrint(const JsonEncoder.withIndent('  ').convert(apiPayload));
    debugPrint('========================');

    return apiPayload;
  }

  static String _mapSex(String genderEnum) {
    switch (genderEnum.toLowerCase()) {
      case 'vrouwelijk':
        return 'female';
      case 'mannelijk':
        return 'male';
      case 'onbekend':
      default:
        return 'unknown';
    }
  }

  static String _mapAge(String ageKey) {
    switch (ageKey) {
      case 'pasGeborenAmount':
        return 'Pasgeboren';
      case 'onvolwassenAmount':
        return 'Onvolwassen';
      case 'volwassenAmount':
        return 'Volwassen';
      case 'unknownAmount':
      default:
        return 'Onbekend';
    }
  }

  static String _mapCondition(String condition) {
    switch (condition.toLowerCase()) {
      case 'gezond':
        return 'healthy';
      case 'ziek':
        return 'impaired';
      case 'dood':
        return 'dead';
      default:
        return 'other';
    }
  }

  static String _mapLifeStage(String age) {
    switch (age.toLowerCase()) {
      case 'pasgeboren':
        return 'infant';
      case 'onvolwassen':
        return 'adolescent';
      case 'volwassen':
        return 'adult';
      default:
        return 'unknown';
    }
  }
}
