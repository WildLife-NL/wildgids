import 'dart:convert';

import 'package:latlong2/latlong.dart';

/// Explicit links between supplied trail IDs and published park entrance pins.
/// A trail endpoint or a nearby amenity is never treated as an entrance.
class ConfirmedTrailEntrance {
  const ConfirmedTrailEntrance({
    required this.id,
    required this.name,
    required this.point,
    required this.routeIds,
    required this.source,
    required this.verifiedOn,
  });

  final String id;
  final String name;
  final LatLng point;
  final Set<String> routeIds;
  final Uri source;
  final DateTime verifiedOn;

  Uri get directions => Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    'destination': '${point.latitude},${point.longitude}',
    'travelmode': 'walking',
  });
}

List<ConfirmedTrailEntrance> parseConfirmedTrailEntrances(String source) {
  final root = jsonDecode(source) as Map<String, dynamic>;
  if (root['entrances'] is! List) {
    throw const FormatException('Expected confirmed entrances');
  }
  final entries = <ConfirmedTrailEntrance>[];
  final ids = <String>{};
  for (final raw in root['entrances'] as List) {
    if (raw is! Map || raw['confirmed'] != true) continue;
    final id = raw['id'];
    final name = raw['name'];
    final lat = raw['latitude'];
    final lon = raw['longitude'];
    final routes = raw['routeIds'];
    final evidence = Uri.tryParse(raw['source']?.toString() ?? '');
    final date = DateTime.tryParse(raw['verifiedOn']?.toString() ?? '');
    if (id is! String ||
        id.isEmpty ||
        !ids.add(id) ||
        name is! String ||
        name.trim().isEmpty ||
        lat is! num ||
        !lat.isFinite ||
        lat.abs() > 90 ||
        lon is! num ||
        !lon.isFinite ||
        lon.abs() > 180 ||
        routes is! List ||
        routes.isEmpty ||
        routes.any((id) => id is! String || id.isEmpty) ||
        evidence == null ||
        evidence.scheme != 'https' ||
        evidence.host != 'www.np-zuidkennemerland.nl' ||
        date == null) {
      throw const FormatException('Invalid confirmed entrance evidence');
    }
    entries.add(
      ConfirmedTrailEntrance(
        id: id,
        name: name.trim(),
        point: LatLng(lat.toDouble(), lon.toDouble()),
        routeIds: Set.unmodifiable(routes.cast<String>()),
        source: evidence,
        verifiedOn: date,
      ),
    );
  }
  return List.unmodifiable(entries);
}
