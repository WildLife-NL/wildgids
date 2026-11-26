import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:latlong2/latlong.dart';
import 'package:wildgids/models/park_walking_route.dart';

double _segmentFraction(Offset point, Offset a, Offset b) {
  final line = b - a;
  if (line.distanceSquared == 0) return 0;
  final relative = point - a;
  return ((relative.dx * line.dx + relative.dy * line.dy) /
          line.distanceSquared)
      .clamp(0.0, 1.0);
}

/// Finger-sized hit testing in map pixels. Separate lines are never joined.
List<ParkWalkingRoute> trailsAtMapPoint({
  required LatLng point,
  required Iterable<ParkWalkingRoute> routes,
  required Offset Function(LatLng) project,
  double tolerance = 24,
}) {
  final tap = project(point);
  final hits = <(ParkWalkingRoute, double)>[];
  for (final route in routes) {
    var nearest = double.infinity;
    for (final line in route.displaySegments) {
      var a = project(line.first);
      for (final coordinate in line.skip(1)) {
        final b = project(coordinate);
        final nearestPoint = a + (b - a) * _segmentFraction(tap, a, b);
        nearest = math.min(nearest, (tap - nearestPoint).distance);
        a = b;
      }
    }
    if (nearest <= tolerance) hits.add((route, nearest));
  }
  hits.sort((a, b) => a.$2.compareTo(b.$2));
  if (hits.isEmpty) return const [];
  // Shared or nearly shared lines offer a choice instead of guessing a route.
  return hits
      .where((hit) => hit.$2 <= hits.first.$2 + 6)
      .map((hit) => hit.$1)
      .toList(growable: false);
}

/// Approximate nearest point on the real trail, followed by geodesic distance.
/// Never measures to a map camera, a fabricated entrance or a gap between parts.
double distanceToTrailMeters(LatLng from, ParkWalkingRoute route) {
  final xScale = 111320 * math.cos(from.latitudeInRad);
  Offset project(LatLng p) => Offset(
    (p.longitude - from.longitude) * xScale,
    (p.latitude - from.latitude) * 111320,
  );
  var best = double.infinity;
  LatLng? nearest;
  for (final line in route.segments) {
    for (var i = 1; i < line.length; i++) {
      final a = line[i - 1];
      final b = line[i];
      final pa = project(a);
      final pb = project(b);
      final t = _segmentFraction(Offset.zero, pa, pb);
      final distance = (pa + (pb - pa) * t).distanceSquared;
      if (distance < best) {
        best = distance;
        nearest = LatLng(
          a.latitude + (b.latitude - a.latitude) * t,
          a.longitude + (b.longitude - a.longitude) * t,
        );
      }
    }
  }
  return const Distance(
    roundResult: false,
  ).as(LengthUnit.Meter, from, nearest!);
}

String trailDistanceLabel(double meters) =>
    meters < 1000
        ? '${(meters / 10).round() * 10} m'
        : '${(meters / 1000).toStringAsFixed(meters >= 100000 ? 0 : 1).replaceAll('.', ',')} km';
