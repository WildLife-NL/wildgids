import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:wildgids/models/park_walking_route.dart';
import 'package:wildgids/utils/trail_geometry.dart';
import '../models/park_walking_route_test.dart' show routeFixture;

void main() {
  Offset project(LatLng point) =>
      Offset(point.longitude * 10000, point.latitude * 10000);
  final route =
      parseParkWalkingRoutes(
        routeFixture(
          geometry: {
            'type': 'MultiLineString',
            'coordinates': [
              [
                [4.60, 52.40],
                [4.61, 52.40],
              ],
              [
                [4.70, 52.40],
                [4.71, 52.40],
              ],
            ],
          },
        ),
      ).single;

  test('map taps have a finger-sized target around the actual lines', () {
    List<ParkWalkingRoute> hits(LatLng point) =>
        trailsAtMapPoint(point: point, routes: [route], project: project);
    expect(hits(const LatLng(52.4022, 4.605)), [route]);
    expect(hits(const LatLng(52.4025, 4.605)), isEmpty);
    expect(hits(const LatLng(52.40, 4.65)), isEmpty); // gap, never a line
    expect(
      trailsAtMapPoint(
        point: const LatLng(52.40, 4.605),
        routes: [],
        project: project,
      ),
      isEmpty,
    );
  });

  test('shared lines offer both routes rather than silently choosing one', () {
    final duplicate =
        parseParkWalkingRoutes(
          routeFixture(
            geometry: {
              'type': 'LineString',
              'coordinates': [
                [4.6, 52.4],
                [4.61, 52.4],
              ],
            },
            properties: {'OBJECTID': 2, 'naam': 'Tweede route'},
          ),
        ).single;
    final hits = trailsAtMapPoint(
      point: const LatLng(52.4, 4.605),
      routes: [route, duplicate],
      project: project,
    );
    expect(hits.map((r) => r.id).toSet(), {'1', '2'});
  });

  test(
    'GPS distance is to the nearest trail point, not the first coordinate',
    () {
      final meters = distanceToTrailMeters(const LatLng(52.401, 4.605), route);
      expect(meters, inInclusiveRange(110, 113));
      expect(
        distanceToTrailMeters(const LatLng(52.4, 4.605), route),
        lessThan(1),
      );
    },
  );

  test('distance never treats a disconnected gap as part of a trail', () {
    expect(
      distanceToTrailMeters(const LatLng(52.4, 4.65), route),
      greaterThan(2500),
    );
  });

  test('distance labels use approximate Dutch metres and kilometres', () {
    expect(trailDistanceLabel(137), '140 m');
    expect(trailDistanceLabel(2350), '2,4 km');
    expect(trailDistanceLabel(125123), '125 km');
  });
}
