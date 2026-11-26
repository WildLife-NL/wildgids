import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wildgids/models/park_boundary.dart';

void main() {
  test('the PDOK park outline keeps its closed exterior and five holes', () {
    final boundary = parseParkBoundary(
      File(
        'assets/routes/zuid_kennemerland_boundary.geojson',
      ).readAsStringSync(),
    );
    expect(boundary.name, 'Zuid-Kennemerland');
    expect(boundary.rings, hasLength(6));
    expect(boundary.rings.expand((r) => r), hasLength(2342));
    for (final ring in boundary.rings) {
      expect(ring.first, ring.last);
      expect(
        ring.every(
          (p) =>
              p.latitude > 52.36 &&
              p.latitude < 52.46 &&
              p.longitude > 4.53 &&
              p.longitude < 4.64,
        ),
        isTrue,
      );
    }
  });

  test(
    'an open or projected outline cannot silently draw as a park boundary',
    () {
      expect(
        () => parseParkBoundary(
          jsonEncode({
            'geometry': {
              'type': 'Polygon',
              'coordinates': [
                [
                  [4, 52],
                  [5, 52],
                  [5, 53],
                  [4, 53],
                ],
              ],
            },
            'properties': {'naam': 'Broken'},
          }),
        ),
        throwsFormatException,
      );
      expect(
        () => parseParkBoundary(
          jsonEncode({
            'geometry': {
              'type': 'Polygon',
              'coordinates': [
                [
                  [100000, 400000],
                  [110000, 400000],
                  [110000, 410000],
                  [100000, 400000],
                ],
              ],
            },
            'properties': {'naam': 'Projected'},
          }),
        ),
        throwsFormatException,
      );
    },
  );
}
