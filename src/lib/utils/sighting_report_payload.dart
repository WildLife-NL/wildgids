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

    reportOfSighting['humanActivity'] = human;
    reportOfSighting['perceivedAnimalActivity'] = perceived;
    reportOfSighting['involvedAnimals'] ??= [];

    if (SightingReportActivityCatalog.isOtherHuman(human)) {
      final other = sighting.humanActivityOther?.trim() ?? '';
      if (other.isNotEmpty) {
        reportOfSighting['humanActivityOther'] = other;
      } else {
        reportOfSighting.remove('humanActivityOther');
      }
    } else {
      reportOfSighting.remove('humanActivityOther');
    }

    if (SightingReportActivityCatalog.isOtherPerceivedAnimal(perceived)) {
      final other = sighting.perceivedAnimalActivityOther?.trim() ?? '';
      if (other.isNotEmpty) {
        reportOfSighting['perceivedAnimalActivityOther'] = other;
      } else {
        reportOfSighting.remove('perceivedAnimalActivityOther');
      }
    } else {
      reportOfSighting.remove('perceivedAnimalActivityOther');
    }
  }
}

