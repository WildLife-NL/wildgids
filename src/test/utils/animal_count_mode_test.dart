import 'package:flutter_test/flutter_test.dart';
import 'package:wildgids/data_managers/api_client.dart';
import 'package:wildgids/constants/sighting_report_activities.dart';
import 'package:wildgids/managers/waarneming_flow/animal_sighting_reporting_manager.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_model.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_sighting_model.dart';
import 'package:wildgids/models/api_models/my_interaction.dart';
import 'package:wildgids/models/beta_models/cached_sighting_report.dart';
import 'package:wildgids/models/beta_models/location_model.dart';
import 'package:wildgids/models/enums/animal_count_mode.dart';
import 'package:wildgids/models/enums/location_source.dart';
import 'package:wildgids/models/ui_models/date_time_model.dart';
import 'package:wildgids/utils/sighting_api_transformer.dart';

void main() {
  setUpAll(
    () => SightingReportActivityCatalog.load(
      ApiClient('https://example.invalid'),
    ),
  );

  AnimalSightingModel sighting(AnimalCountMode mode) {
    final animal = AnimalModel(
      animalId: 'deer',
      animalName: 'Damhert',
      animalImagePath: '',
      genderViewCounts: [],
    );
    return AnimalSightingModel(
      animalSelected: animal,
      // Include stale individual details to ensure uncertain counts ignore them.
      animals: [animal],
      animalCount: 3,
      countMode: mode,
      description: 'Bij de bosrand',
      locations: [
        LocationModel(
          latitude: 51.44,
          longitude: 5.47,
          source: LocationSource.manual,
        ),
      ],
      dateTime: DateTimeModel(dateTime: DateTime(2026, 11, 6, 12, 30)),
    );
  }

  for (final mode in AnimalCountMode.values) {
    test(
      '${mode.name} survives local serialization and edits to other fields',
      () {
        final initial = sighting(mode);
        final restored = AnimalSightingModel.fromJson(initial.toJson());
        expect(restored.countMode, mode);
        final manager = AnimalSightingReportingManager();
        manager.updateCurrentanimalSighting(initial);
        manager.updateDateTime(DateTime(2026, 11, 7));
        manager.updateLocation(
          LocationModel(
            latitude: 52,
            longitude: 5,
            source: LocationSource.manual,
          ),
        );
        expect(manager.getCurrentanimalSighting()!.countMode, mode);
      },
    );

    test(
      '${mode.name} survives API and offline storage without inventing counts',
      () {
        final payload = SightingApiTransformer.transformForApi(sighting(mode));
        final cached = CachedSightingReport(payload).toJson();
        expect(cached, payload);
        final animals =
            (cached['reportOfSighting'] as Map)['involvedAnimals'] as List;
        expect(animals.length, mode == AnimalCountMode.exact ? 3 : 0);
        expect(payload.containsKey('countMode'), isFalse);
        expect(payload.containsKey('description'), isFalse);
        expect(payload['notes'], contains('Bij de bosrand'));
        final interaction = MyInteraction.fromJson({
          ...cached,
          'moment': payload['moment'],
          'timestamp': payload['moment'],
        });
        expect(AnimalCountMode.fromNotes(interaction.description), mode);
        if (mode != AnimalCountMode.exact) {
          expect(interaction.description, contains(mode.note));
        }
      },
    );
  }

  test('Legacy reports default to an exact count', () {
    expect(AnimalSightingModel.fromJson({}).countMode, AnimalCountMode.exact);
    expect(AnimalCountMode.fromNotes('Old notes'), AnimalCountMode.exact);
  });
}
