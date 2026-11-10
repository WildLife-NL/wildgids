import 'package:flutter_test/flutter_test.dart';
import 'package:wildgids/models/ui_models/weather_living_lab.dart';

void main() {
  final lab = <String, Object?>{
    'ID': 'backend-id',
    'name': 'Backend name',
    'definition': [
      {'latitude': 51, 'longitude': 5},
      {'latitude': 51, 'longitude': 7},
      {'latitude': 53, 'longitude': 7},
      {'latitude': 53, 'longitude': 5},
      {'latitude': 51, 'longitude': 5},
    ],
  };

  test('uses API IDs, names and bounds, without duplicate-vertex bias', () {
    final result = WeatherLivingLab.fromJson(lab);
    expect(result.id, 'backend-id');
    expect(result.name, 'Backend name');
    expect(result.center!.latitude, 52);
    expect(result.center!.longitude, 6);
  });

  for (final definition in [
    null,
    [],
    'bad',
    [
      {'latitude': 91, 'longitude': 5},
    ],
    [
      {'latitude': double.nan, 'longitude': 5},
    ],
    [
      {'latitude': 51, 'longitude': '5'},
    ],
    [
      {'latitude': 51, 'longitude': 5},
      null,
      {'latitude': 52, 'longitude': 6},
    ],
  ]) {
    test('does not invent a location for invalid boundary $definition', () {
      expect(
        WeatherLivingLab.fromJson({...lab, 'definition': definition}).center,
        isNull,
      );
    });
  }

  test(
    'accepts null/empty lists and rejects malformed identities and duplicates',
    () {
      expect(WeatherLivingLab.parseList(null), isEmpty);
      expect(WeatherLivingLab.parseList([]), isEmpty);
      for (final data in [
        {},
        [null],
        [lab, lab],
        [
          {...lab, 'ID': ''},
        ],
        [
          {...lab, 'name': null},
        ],
      ]) {
        expect(() => WeatherLivingLab.parseList(data), throwsFormatException);
      }
    },
  );
}
