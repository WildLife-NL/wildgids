import 'package:wildgids/constants/sighting_report_activities.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_sighting_model.dart';

class SightingReportPayload {
  SightingReportPayload._();

  static void applyToReportOfSighting(
    Map<String, dynamic> reportOfSighting,
    AnimalSightingModel sighting,
  ) {
    final human = SightingReportActivityCatalog.normalizeHuman(
      sighting.humanActivity,
    );
    final perceived = SightingReportActivityCatalog.normalizePerceivedAnimal(
      sighting.perceivedAnimalActivity,
    );

    // API requires both fields; "unknown" is a valid enum value.
    reportOfSighting['humanActivity'] = human;
    reportOfSighting['perceivedAnimalActivity'] = perceived;
    reportOfSighting['involvedAnimals'] ??= [];

    if (SightingReportActivityCatalog.isOtherHuman(human)) {
      final other = sighting.humanActivityOther?.trim() ?? '';
      if (other.isEmpty) {
        throw StateError(
          'Vul een toelichting in bij "Anders" voor jouw activiteit.',
        );
      }
      reportOfSighting['humanActivityOther'] = other;
    } else {
      reportOfSighting.remove('humanActivityOther');
    }

    if (SightingReportActivityCatalog.isOtherPerceivedAnimal(perceived)) {
      final other = sighting.perceivedAnimalActivityOther?.trim() ?? '';
      if (other.isEmpty) {
        throw StateError(
          'Vul een toelichting in bij "Anders" voor de activiteit van het dier.',
        );
      }
      reportOfSighting['perceivedAnimalActivityOther'] = other;
    } else {
      reportOfSighting.remove('perceivedAnimalActivityOther');
    }
  }
}

