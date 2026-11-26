import 'dart:convert';
import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// A supplied path. Each GeoJSON line stays separate, including in the renderer.
class ParkWalkingRoute {
  final String id;
  final String name;
  final String? entrance;
  final String? operatorName;
  final String? routeNumber;
  final String? colorName;
  final List<List<LatLng>> segments;
  final List<List<LatLng>> displaySegments;
  final double distanceMeters;

  ParkWalkingRoute._({
    required this.id,
    required this.name,
    required this.entrance,
    required this.operatorName,
    required this.routeNumber,
    required this.colorName,
    required this.segments,
  }) : displaySegments = List.unmodifiable(segments.map(_simplify)),
       distanceMeters = _distance(segments);

  Iterable<LatLng> get points => segments.expand((line) => line);

  String get distanceLabel =>
      distanceMeters < 1000
          ? '${distanceMeters.round()} m'
          : '${(distanceMeters / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';

  bool matches(String query) {
    final text =
        [
          name,
          entrance,
          operatorName,
          routeNumber,
          colorName,
        ].whereType<String>().join(' ').toLowerCase();
    return query
        .toLowerCase()
        .trim()
        .split(RegExp(r'\s+'))
        .every(text.contains);
  }
}

String? _text(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

/// GeoJSON uses longitude, latitude. Reject other CRSs rather than drawing
/// projected coordinates in the wrong place. No network or GPS is needed.
List<ParkWalkingRoute> parseParkWalkingRoutes(String source) {
  final root = jsonDecode(source) as Map<String, dynamic>;
  final crs = root['crs'];
  if (crs != null) {
    final properties = crs is Map ? crs['properties'] : null;
    final name = properties is Map ? properties['name'] : null;
    if (name != 'urn:ogc:def:crs:OGC:1.3:CRS84' &&
        name != 'EPSG:4326' &&
        name != 'urn:ogc:def:crs:EPSG::4326') {
      throw const FormatException('Unsupported walking route CRS');
    }
  }
  if (root['type'] != 'FeatureCollection' || root['features'] is! List) {
    throw const FormatException('Expected a GeoJSON FeatureCollection');
  }
  final ids = <String>{};
  final routes = <ParkWalkingRoute>[];
  for (final feature in root['features'] as List) {
    final properties = feature['properties'] as Map<String, dynamic>? ?? {};
    final name = _text(properties['naam']) ?? _text(properties['naampwn']);
    final id = _text(properties['OBJECTID']) ?? _text(feature['id']);
    if (id == null || !ids.add(id)) {
      throw const FormatException('Missing or duplicate walking route ID');
    }
    final geometry = feature['geometry'] as Map<String, dynamic>;
    final List lines;
    switch (geometry['type']) {
      case 'LineString':
        lines = [geometry['coordinates']];
      case 'MultiLineString':
        lines = geometry['coordinates'] as List;
      default:
        throw const FormatException('Expected line geometry');
    }
    if (lines.isEmpty) throw const FormatException('Empty walking route');
    final segments = <List<LatLng>>[];
    for (final line in lines) {
      if (line is! List || line.length < 2) {
        throw const FormatException('A path needs at least two points');
      }
      final points = <LatLng>[];
      for (final coordinate in line) {
        if (coordinate is! List ||
            coordinate.length < 2 ||
            coordinate[0] is! num ||
            coordinate[1] is! num) {
          throw const FormatException('Invalid route coordinate');
        }
        final lon = (coordinate[0] as num).toDouble();
        final lat = (coordinate[1] as num).toDouble();
        if (!lon.isFinite ||
            !lat.isFinite ||
            lon.abs() > 180 ||
            lat.abs() > 90) {
          throw const FormatException('Route coordinate is outside WGS84');
        }
        points.add(LatLng(lat, lon));
      }
      segments.add(List.unmodifiable(points));
    }
    // Keep substantial unnamed source paths, but do not count gaps as distance
    // or turn an entrance label into an invented route name.
    if (name == null && _distance(segments) < 600) continue;
    final entrance = _text(properties['naamingang']);
    final color =
        _text(properties['kleur_resolved']) ?? _text(properties['kleur']);
    routes.add(
      ParkWalkingRoute._(
        id: id,
        name: name ?? 'Wandelpad $id',
        entrance: entrance,
        operatorName:
            _text(properties['beheerder_resolved']) ??
            _text(properties['beheerder']),
        routeNumber: _text(properties['pwnnummer']),
        colorName: color,
        segments: List.unmodifiable(segments),
      ),
    );
  }
  routes.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return List.unmodifiable(routes);
}

double _distance(List<List<LatLng>> segments) {
  const distance = Distance(roundResult: false);
  var meters = 0.0;
  for (final line in segments) {
    for (var i = 1; i < line.length; i++) {
      meters += distance.as(LengthUnit.Meter, line[i - 1], line[i]);
    }
  }
  return meters;
}

/// Two-metre display tolerance in a local metric projection. Original points
/// remain intact for distance and bounds; endpoints and line gaps are retained.
List<LatLng> _simplify(List<LatLng> points) {
  if (points.length <= 2) return points;
  final origin = points.first;
  final longitudeScale = 111320 * math.cos(origin.latitudeInRad);
  final xs =
      points
          .map((p) => (p.longitude - origin.longitude) * longitudeScale)
          .toList();
  final ys =
      points.map((p) => (p.latitude - origin.latitude) * 111320).toList();
  final keep = <int>{0, points.length - 1};
  final pending = <(int, int)>[(0, points.length - 1)];
  while (pending.isNotEmpty) {
    final (first, last) = pending.removeLast();
    final dx = xs[last] - xs[first];
    final dy = ys[last] - ys[first];
    final squaredLength = dx * dx + dy * dy;
    var maxDistance = 4.0;
    var index = -1;
    for (var i = first + 1; i < last; i++) {
      final t =
          squaredLength == 0
              ? 0.0
              : (((xs[i] - xs[first]) * dx + (ys[i] - ys[first]) * dy) /
                      squaredLength)
                  .clamp(0.0, 1.0);
      final px = xs[i] - xs[first] - t * dx;
      final py = ys[i] - ys[first] - t * dy;
      final squaredDistance = px * px + py * py;
      if (squaredDistance > maxDistance) {
        maxDistance = squaredDistance;
        index = i;
      }
    }
    if (index != -1) {
      keep.add(index);
      pending.add((first, index));
      pending.add((index, last));
    }
  }
  final ordered = keep.toList()..sort();
  return List.unmodifiable(ordered.map((i) => points[i]));
}
