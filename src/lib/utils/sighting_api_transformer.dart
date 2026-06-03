import 'package:flutter/material.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_sighting_model.dart';
import 'package:wildgids/models/beta_models/sighted_animal_model.dart';
import 'package:wildgids/models/enums/location_source.dart';
import 'package:wildgids/utils/api_datetime.dart';
import 'package:wildgids/utils/sighting_report_payload.dart';
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
    // Prefer system location if available, fall back to manual if GPS wasn't acquired
    final systemLocation = sighting.locations!.firstWhere(
      (loc) => loc.source == LocationSource.system,
      orElse: () {
        // GPS wasn't acquired - try to use manual location as fallback
        final manual = sighting.locations!.firstWhere(
          (loc) => loc.source == LocationSource.manual,
          orElse: () => throw StateError('At least one location (system or manual) is required'),
        );
        debugPrint('âš ï¸ System location not available, using manual location as fallback');
        return manual;
      },
    );
    debugPrint('System Location: ${systemLocation.toJson()}');

    // Prefer manual location; if not provided, fall back to system
    final manualLocation = sighting.locations!.firstWhere(
      (loc) => loc.source == LocationSource.manual,
      orElse: () => systemLocation,
    );
    debugPrint('Manual Location: ${manualLocation.toJson()}');

    // Transform animals to SightedAnimal format
    final List<SightedAnimal> sightedAnimals = [];
    for (final animal in sighting.animals!) {
      final condition =
          animal.condition?.toString().split('.').last ?? 'unknown';
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

    if (sightedAnimals.isEmpty) {
      final count = sighting.animalCount ?? 1;
      for (var i = 0; i < count; i++) {
        sightedAnimals.add(
          SightedAnimal(
            condition: 'unknown',
            lifeStage: 'unknown',
            sex: 'unknown',
          ),
        );
      }
    }

    final apiPayload = {
      "description": _safeDescription(sighting.description),
      "location": {
        "latitude": systemLocation.latitude,
        "longitude": systemLocation.longitude,
      },
      "moment": ApiDateTime.toApiIso(sighting.dateTime!.dateTime!),
      "place": {
        "latitude": manualLocation.latitude,
        "longitude": manualLocation.longitude,
      },
      "reportOfSighting": <String, dynamic>{
        "involvedAnimals":
            sightedAnimals.map((animal) => animal.toJson()).toList(),
      },
      "speciesID": sighting.animalSelected!.animalId,
      "typeID": 1,
    };

    final reportOfSighting =
        apiPayload['reportOfSighting'] as Map<String, dynamic>;
    _ensureInvolvedAnimalsList(reportOfSighting);
    SightingReportPayload.applyToReportOfSighting(reportOfSighting, sighting);
    _ensureInvolvedAnimalsList(reportOfSighting);

    debugPrint('=== Final API Payload ===');
    debugPrint(const JsonEncoder.withIndent('  ').convert(apiPayload));
    debugPrint('========================');

    return apiPayload;
  }

  /// API expects a JSON array; guard against accidental string/other types.
  static void _ensureInvolvedAnimalsList(Map<String, dynamic> reportOfSighting) {
    final raw = reportOfSighting['involvedAnimals'];
    if (raw is List) {
      reportOfSighting['involvedAnimals'] = raw
          .whereType<Map>()
          .map(
            (e) => e is Map<String, dynamic>
                ? e
                : Map<String, dynamic>.from(e),
          )
          .toList();
      return;
    }
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          reportOfSighting['involvedAnimals'] = decoded
              .whereType<Map>()
              .map(
                (e) => e is Map<String, dynamic>
                    ? e
                    : Map<String, dynamic>.from(e),
              )
              .toList();
          return;
        }
      } catch (_) {
        // fall through to default
      }
    }
    reportOfSighting['involvedAnimals'] = <Map<String, dynamic>>[];
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
      case 'unknown':
      case 'onbekend':
        return 'unknown';
      // Enum / legacy values that are not explicit health states
      case 'andere':
      case 'levend':
      case 'other':
        return 'unknown';
      default:
        return 'unknown';
    }
  }

  static String _safeDescription(String? description) {
  final trimmed = description?.trim();

  if (trimmed != null && trimmed.isNotEmpty) {
    return trimmed;
  }

  return 'Geen beschrijving opgegeven';
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

