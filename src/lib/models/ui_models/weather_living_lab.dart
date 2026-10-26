import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// A backend living lab with an approximate weather point from its bounds.
class WeatherLivingLab {
  const WeatherLivingLab({required this.id, required this.name, this.center});

  final String id;
  final String name;
  final LatLng? center;

  factory WeatherLivingLab.fromJson(Map<String, dynamic> json) {
    final id = json['ID'];
    final name = json['name'];
    if (id is! String ||
        id.trim().isEmpty ||
        name is! String ||
        name.trim().isEmpty) {
      throw const FormatException('Living lab ID and name are required');
    }
    final definition = json['definition'];
    final points = <LatLng>[];
    if (definition is List) {
      for (final point in definition) {
        if (point is! Map) {
          points.clear();
          break;
        }
        final lat = point['latitude'];
        final lng = point['longitude'];
        if (lat is! num ||
            lng is! num ||
            !lat.isFinite ||
            !lng.isFinite ||
            lat.abs() > 90 ||
            lng.abs() > 180) {
          points.clear();
          break;
        }
        points.add(LatLng(lat.toDouble(), lng.toDouble()));
      }
    }
    LatLng? center;
    if (points.length >= 3) {
      final latitudes = points.map((p) => p.latitude);
      final longitudes = points.map((p) => p.longitude);
      center = LatLng(
        (latitudes.reduce(math.min) + latitudes.reduce(math.max)) / 2,
        (longitudes.reduce(math.min) + longitudes.reduce(math.max)) / 2,
      );
    }
    return WeatherLivingLab(id: id.trim(), name: name.trim(), center: center);
  }

  static List<WeatherLivingLab> parseList(Object? json) {
    if (json == null) return const [];
    if (json is! List) throw const FormatException('Expected living lab list');
    final ids = <String>{};
    return List.unmodifiable(
      json.map((entry) {
        if (entry is! Map<String, dynamic>) {
          throw const FormatException('Invalid living lab');
        }
        final lab = WeatherLivingLab.fromJson(entry);
        if (!ids.add(lab.id)) {
          throw const FormatException('Duplicate living lab');
        }
        return lab;
      }),
    );
  }
}
