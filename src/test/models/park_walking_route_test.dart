import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:wildgids/models/park_walking_route.dart';

String routeFixture({
  Map<String, dynamic>? geometry,
  Map<String, dynamic>? properties,
}) => jsonEncode({
  'type': 'FeatureCollection',
  'features': [
    {
      'type': 'Feature',
      'properties': {
        'OBJECTID': 1,
        'naam': 'Duinpad',
        'kleur': 'blauw',
        ...?properties,
      },
      'geometry':
          geometry ??
          {
            'type': 'MultiLineString',
            'coordinates': [
              [
                [4.6, 52.4],
                [4.60001, 52.4],
                [4.601, 52.4],
              ],
              [
                [4.7, 52.5],
                [4.701, 52.5],
              ],
            ],
          },
    },
  ],
});

void main() {
  test(
    'longitude/latitude and disconnected parts survive parsing and display simplification',
    () {
      final route = parseParkWalkingRoutes(routeFixture()).single;
      expect(route.segments.first.first, const LatLng(52.4, 4.6));
      expect(route.segments, hasLength(2));
      expect(route.displaySegments, hasLength(2));
      expect(route.segments.first, hasLength(3));
      expect(route.displaySegments.first, hasLength(2));
      expect(route.displaySegments.first.last, route.segments.first.last);
      expect(route.displaySegments.last.first, route.segments.last.first);
      // The gap is >10 km; the two real parts together are about 136 metres.
      expect(route.distanceMeters, inInclusiveRange(130, 145));
    },
  );

  test(
    'single lines use a source name and short unnamed paths are excluded',
    () {
      final route =
          parseParkWalkingRoutes(
            routeFixture(
              properties: {
                'naam': '  ',
                'naampwn': ' Koevlak groen ',
                'naamingang': ' Koevlak ',
                'kleur': 'groen',
              },
              geometry: {
                'type': 'LineString',
                'coordinates': [
                  [4.6, 52.4],
                  [4.601, 52.4],
                ],
              },
            ),
          ).single;
      expect(route.name, 'Koevlak groen');
      expect(route.entrance, 'Koevlak');
      expect(route.operatorName, isNull);
      expect(route.segments, hasLength(1));
      expect(route.matches('koevlak groen'), isTrue);
      expect(route.matches('ander park'), isFalse);
      final unnamed = parseParkWalkingRoutes(
        routeFixture(properties: {'naam': null}),
      );
      expect(unnamed, isEmpty);
      expect(
        parseParkWalkingRoutes(
          routeFixture(properties: {'naam': ' ', 'naamingang': 'Koevlak'}),
        ),
        isEmpty,
      );
    },
  );

  test('long unnamed paths use a neutral ID label without inventing names', () {
    final route =
        parseParkWalkingRoutes(
          routeFixture(
            properties: {'naam': null, 'naamingang': 'Ingang', 'OBJECTID': 61},
            geometry: {
              'type': 'LineString',
              'coordinates': [
                [4.6, 52.4],
                [4.61, 52.4],
              ],
            },
          ),
        ).single;
    expect(route.name, 'Wandelpad 61');
    expect(route.distanceMeters, greaterThan(600));
    // A 10 km gap between the default short parts must not make a long path.
    expect(
      parseParkWalkingRoutes(routeFixture(properties: {'naam': null})),
      isEmpty,
    );
    final namedShort = parseParkWalkingRoutes(routeFixture()).single;
    expect(namedShort.distanceMeters, lessThan(600));
  });

  test(
    'projected CRS, invalid coordinates and duplicate IDs cannot silently draw incorrect paths',
    () {
      final projected = jsonDecode(routeFixture()) as Map<String, dynamic>;
      projected['crs'] = {
        'properties': {'name': 'EPSG:28992'},
      };
      expect(
        () => parseParkWalkingRoutes(jsonEncode(projected)),
        throwsFormatException,
      );
      final duplicate = jsonDecode(routeFixture()) as Map<String, dynamic>;
      (duplicate['features'] as List).add(duplicate['features'][0]);
      expect(
        () => parseParkWalkingRoutes(jsonEncode(duplicate)),
        throwsFormatException,
      );
      expect(
        () => parseParkWalkingRoutes(
          routeFixture(
            geometry: {
              'type': 'LineString',
              'coordinates': [
                [100000, 450000],
                [100001, 450001],
              ],
            },
          ),
        ),
        throwsFormatException,
      );
    },
  );

  test(
    'the bundled Zuid-Kennemerland paths retain complete separate source lines',
    () async {
      final source =
          await File(
            'assets/routes/park_walking_routes.geojson',
          ).readAsString();
      final routes = parseParkWalkingRoutes(source);
      expect(routes, hasLength(38));
      expect(routes.map((r) => r.id).toSet(), hasLength(38));
      expect(routes.fold<int>(0, (n, r) => n + r.segments.length), 190);
      final points = routes.expand((r) => r.points).toList();
      expect(points, hasLength(90473));
      expect(
        points.every(
          (p) =>
              p.latitude > 52.366 &&
              p.latitude < 52.46 &&
              p.longitude > 4.52 &&
              p.longitude < 4.633,
        ),
        isTrue,
      );
      expect(routes.any((r) => r.name == 'Bleek en Berg groen'), isTrue);
      expect(routes.any((r) => r.name == 'Koevlak groen'), isTrue);
      expect(routes.any((r) => r.name == 'Albertdalpad'), isFalse);
      expect(routes.any((r) => r.name == 'Bergerbos'), isFalse);
      expect(routes.any((r) => r.id == '58'), isFalse);
      for (final route in routes) {
        expect(route.distanceMeters, greaterThan(0));
        for (var i = 0; i < route.segments.length; i++) {
          expect(route.displaySegments[i].first, route.segments[i].first);
          expect(route.displaySegments[i].last, route.segments[i].last);
        }
      }
      final displayPoints =
          routes.expand((r) => r.displaySegments.expand((s) => s)).length;
      expect(displayPoints, lessThan(points.length ~/ 2));
    },
  );
}
