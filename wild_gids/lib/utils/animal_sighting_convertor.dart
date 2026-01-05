import 'package:wildgids/models/animal_waarneming_models/animal_sighting_model.dart';

class AnimalSightingConvertor {
  /// Converts an AnimalSightingModel to the format required by the API
  static Map<String, dynamic> toApiFormat(AnimalSightingModel report) {
    final List<Map<String, dynamic>> allInvolvedAnimals = [];

    for (final animal in report.animals ?? []) {
      allInvolvedAnimals.addAll(transformInvolvedAnimals(animal));
    }

    if (report.locations == null || report.locations!.isEmpty) {
      throw StateError('Location is required for API submission');
    }

    final systemLocation = report.locations!.firstWhere(
      (loc) => loc.source.toString().split('.').last == 'system',
    );
    final userLocation = report.locations!.firstWhere(
      (loc) => loc.source.toString().split('.').last == 'manual',
    );

    return {
      "description": report.description,
      "location": {
        "latitude": systemLocation.latitude,
        "longitude": systemLocation.longitude,
      },
      "moment": report.dateTime?.dateTime?.toIso8601String(),
      "place": {
        "latitude": userLocation.latitude,
        "longitude": userLocation.longitude,
      },
      "reportOfSighting": {"involvedAnimals": allInvolvedAnimals},
      "speciesID":
          report
              .animalSelected
              ?.animalId, // Make sure this is not null when sending
      "typeID": 1,
    };
  }

  static List<Map<String, dynamic>> transformInvolvedAnimals(dynamic animal) {
    final List<Map<String, dynamic>> involvedAnimals = [];

    final condition = animal.condition.toString().split('.').last;
    final mappedCondition = mapCondition(condition);

    for (final genderView in animal.genderViewCounts) {
      final genderString = genderView.gender.toString().split('.').last;
      final sex = mapSex(genderString);
      final viewCount = genderView.viewCount;

      void addEntries(int amount, String ageKey) {
        final age = mapAge(ageKey);
        final lifeStage = mapLifeStage(age);

        for (int i = 0; i < amount; i++) {
          involvedAnimals.add({
            "condition": mappedCondition,
            "lifeStage": lifeStage,
            "sex": sex,
          });
        }
      }

      addEntries(viewCount.pasGeborenAmount, 'pasGeborenAmount');
      addEntries(viewCount.onvolwassenAmount, 'onvolwassenAmount');
      addEntries(viewCount.volwassenAmount, 'volwassenAmount');
      addEntries(viewCount.unknownAmount, 'unknownAmount');
    }

    return involvedAnimals;
  }

  static String mapSex(String genderEnum) {
    switch (genderEnum) {
      case 'vrouwelijk':
        return 'female';
      case 'mannelijk':
        return 'male';
      case 'onbekend':
      default:
        return 'unknown';
    }
  }

  static String mapAge(String ageKey) {
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

  static String mapCondition(String condition) {
    switch (condition.toLowerCase()) {
      case 'gezond':
        return 'healthy';
      case 'ziek':
        return 'impaired'; // Confirm this matches your API docs
      case 'dood':
        return 'dead';
      default:
        return 'other';
    }
  }

  static String mapLifeStage(String age) {
    switch (age.toLowerCase()) {
      case 'pasgeboren':
        return 'infant'; // newborn
      case 'onvolwassen':
        return 'adolescent'; // NOT "juvenile" -> API wants "adolescent"
      case 'volwassen':
        return 'adult'; // adult
      default:
        return 'unknown'; // if undefined
    }
  }
}

