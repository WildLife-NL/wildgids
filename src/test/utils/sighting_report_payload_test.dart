import 'package:flutter_test/flutter_test.dart';
import 'package:wildgids/constants/sighting_report_activities.dart';
import 'package:wildgids/data_managers/sighting_report_schema_loader.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_sighting_model.dart';
import 'package:wildgids/utils/sighting_report_payload.dart';

void main() {
  setUpAll(() {
    SightingReportActivityCatalog.loadFromSchemaForTest(
      SightingReportSchema(
        humanActivityValues: ['unknown', 'walking', 'other...'],
        perceivedAnimalActivityValues: ['unknown', 'walking', 'other...'],
      ),
    );
  });

  test('sends humanActivity and perceivedAnimalActivity when value is unknown', () {
    final report = <String, dynamic>{
      'involvedAnimals': <Map<String, dynamic>>[],
    };

    SightingReportPayload.applyToReportOfSighting(
      report,
      AnimalSightingModel(
        humanActivity: 'unknown',
        perceivedAnimalActivity: 'unknown',
      ),
    );

    expect(report['humanActivity'], 'unknown');
    expect(report['perceivedAnimalActivity'], 'unknown');
  });
}
