import 'dart:convert';

import 'package:latlong2/latlong.dart';

class ParkBoundary {
  const ParkBoundary({required this.name, required this.rings});
  final String name;
  // Includes outer and inner rings; holes must not disappear from the outline.
  final List<List<LatLng>> rings;
}

ParkBoundary parseParkBoundary(String source) {
  final feature = jsonDecode(source) as Map<String, dynamic>;
  final geometry = feature['geometry'] as Map<String, dynamic>;
  final List polygons;
  switch (geometry['type']) {
    case 'Polygon':
      polygons = [geometry['coordinates']];
    case 'MultiPolygon':
      polygons = geometry['coordinates'] as List;
    default:
      throw const FormatException('Expected a park polygon');
  }
  final rings = <List<LatLng>>[];
  for (final polygon in polygons) {
    for (final ring in polygon as List) {
      final points = <LatLng>[];
      for (final coordinate in ring as List) {
        final lon = (coordinate[0] as num).toDouble();
        final lat = (coordinate[1] as num).toDouble();
        if (!lon.isFinite ||
            !lat.isFinite ||
            lon.abs() > 180 ||
            lat.abs() > 90) {
          throw const FormatException('Invalid park boundary coordinate');
        }
        points.add(LatLng(lat, lon));
      }
      if (points.length < 4 || points.first != points.last) {
        throw const FormatException('Park boundary ring must be closed');
      }
      rings.add(List.unmodifiable(points));
    }
  }
  if (rings.isEmpty) throw const FormatException('Empty park boundary');
  return ParkBoundary(
    name: feature['properties']['naam'] as String,
    rings: List.unmodifiable(rings),
  );
}
