import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wildgids/managers/map/amenity_map_controller.dart';
import 'package:wildgids/managers/map/living_lab_manager.dart';
import 'package:wildgids/models/ui_models/map_amenity.dart';

void main() {
  const zuid = 'np-zuid-kennemerland';
  const kempen = 'grenspark-kempenbroek';
  List<dynamic> source([String lab = zuid]) =>
      jsonDecode(File(AmenityMapController.parkAssets[lab]!).readAsStringSync())
          as List<dynamic>;
  AmenityCatalog parse(Object? data, [String lab = zuid]) =>
      AmenityCatalog.fromJson(data, livingLabId: lab);

  test('two simple park files preserve all 61 points and nine categories', () {
    expect(
      AmenityMapController.parkAssets.keys.toSet(),
      LivingLabManager().getAllLivingLabs().map((l) => l.id).toSet(),
    );
    final data = source();
    for (final entry in data) {
      expect((entry as Map).keys.toSet(), {
        'type',
        'name',
        'latitude',
        'longitude',
      });
    }
    final points = parse(data).amenities;
    expect(points, hasLength(61));
    expect(points.map((a) => a.id).toSet(), hasLength(61));
    expect(points.every((a) => a.livingLabId == zuid), isTrue);
    expect(points.every((a) => !a.isExample), isTrue);
    final examples = parse(source(kempen), kempen).amenities;
    expect(examples, hasLength(5));
    expect(examples.map((a) => a.id).toSet(), hasLength(5));
    expect(
      examples.every(
        (a) => !a.isExample && a.category == AmenityCategory.toilet,
      ),
      isTrue,
    );
    final expectedCounts = {
      AmenityCategory.parking: 13,
      AmenityCategory.entrance: 22,
      AmenityCategory.estate: 8,
      AmenityCategory.pointOfInterest: 8,
      AmenityCategory.viewpoint: 2,
      AmenityCategory.birdHide: 2,
      AmenityCategory.drinkingWater: 3,
      AmenityCategory.toilet: 2,
      AmenityCategory.visitorCentre: 1,
    };
    for (final entry in expectedCounts.entries) {
      expect(
        points.where((a) => a.category == entry.key),
        hasLength(entry.value),
      );
    }
    for (final point in points) {
      expect(point.latitude, inInclusiveRange(52.3, 52.5));
      expect(point.longitude, inInclusiveRange(4.5, 4.7));
    }
  });

  test('preserves exact coordinates and same-name distinct parking lots', () {
    final points = parse(source()).amenities;
    final toilet = points.singleWhere(
      (a) => a.name == 'Openbaar toilet Duincafé',
    );
    expect(toilet.latitude, 52.3960819);
    expect(toilet.longitude, 4.592633);
    final parking =
        points
            .where((a) => a.name == 'Parkeren bij Bloemendaal aan Zee')
            .toList();
    expect(parking, hasLength(2));
    expect(parking[0].id, isNot(parking[1].id));
    expect(parking[0].latitude, 52.4038589);
    expect(parking[1].latitude, 52.4020523);
  });

  test('automatic IDs survive reordering, insertion and renaming', () {
    final data = source();
    final original = parse(data).amenities;
    final reversed = parse(data.reversed.toList()).amenities;
    expect(
      reversed.map((a) => a.id).toList(),
      original.reversed.map((a) => a.id).toList(),
    );
    data[0]['name'] = 'Updated name';
    expect(parse(data).amenities.first.id, original.first.id);
    data.insert(0, {
      'type': 'toilet',
      'name': 'New toilet',
      'latitude': 52.4,
      'longitude': 4.6,
    });
    expect(parse(data).amenities[1].id, original.first.id);
    expect(
      parse([data[0]], kempen).amenities.single.id,
      isNot(parse([data[0]], zuid).amenities.single.id),
    );
  });

  for (final mutation
      in <String, Object?>{
        'name': '',
        'type': '',
        'latitude': 91,
        'longitude': -181,
        'example': 'true',
      }.entries) {
    test('rejects invalid ${mutation.key}', () {
      final data = source();
      data[0][mutation.key] = mutation.value;
      expect(() => parse(data), throwsFormatException);
    });
  }
  test('rejects non-numeric and non-finite coordinates', () {
    for (final value in ['52.4', double.nan, double.infinity, null]) {
      final data = source();
      data[0]['latitude'] = value;
      expect(() => parse(data), throwsFormatException);
    }
  });
  test('rejects duplicate points and malformed lists', () {
    final data = source();
    data.add({...data.first, 'name': 'Duplicate with another name'});
    expect(() => parse(data), throwsFormatException);
    for (final value in [
      null,
      {},
      [null],
      'bad',
    ]) {
      expect(() => parse(value), throwsFormatException);
    }
    expect(() => parse([], ''), throwsFormatException);
  });
  test('accepts new points in either park without manual IDs', () {
    final row = {
      'type': 'toilet',
      'name': 'Toilet 1',
      'latitude': 51.2,
      'longitude': 5.7,
    };
    expect(parse([row], kempen).amenities.single.livingLabId, kempen);
    final normal = parse([row], kempen).amenities.single;
    expect(normal.isExample, isFalse);
    row['example'] = true;
    final example = parse([row], kempen).amenities.single;
    expect(example.isExample, isTrue);
    expect(example.id, normal.id);
    row['example'] = false;
    expect(parse([row], kempen).amenities.single.isExample, isFalse);
    expect(parse([]).amenities, isEmpty);
  });

  test('proposed categories require explicit app support', () {
    for (final type in ['Picknickplaats', 'bench', null, 1, '', '<script>']) {
      expect(() => AmenityCategory.parse(type), throwsFormatException);
    }
  });
}
