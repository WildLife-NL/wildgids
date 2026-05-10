import 'package:latlong2/latlong.dart';

class ProvincePolygon {
  final String name;
  final List<LatLng> vertices;
  const ProvincePolygon(this.name, this.vertices);
}

// Simplified province rectangles (approximate) to give a friendly label.
const List<ProvincePolygon> _provinces = [
  ProvincePolygon('Drenthe', [
    LatLng(53.2, 6.1),
    LatLng(53.2, 7.1),
    LatLng(52.6, 7.1),
    LatLng(52.6, 6.1),
  ]),
  ProvincePolygon('Flevoland', [
    LatLng(52.8, 5.2),
    LatLng(52.8, 5.9),
    LatLng(52.2, 5.9),
    LatLng(52.2, 5.2),
  ]),
  ProvincePolygon('Friesland', [
    LatLng(53.6, 5.2),
    LatLng(53.6, 6.4),
    LatLng(52.8, 6.4),
    LatLng(52.8, 5.2),
  ]),
  ProvincePolygon('Gelderland', [
    LatLng(52.3, 5.3),
    LatLng(52.3, 6.5),
    LatLng(51.7, 6.5),
    LatLng(51.7, 5.3),
  ]),
  ProvincePolygon('Groningen', [
    LatLng(53.6, 6.5),
    LatLng(53.6, 7.2),
    LatLng(53.1, 7.2),
    LatLng(53.1, 6.5),
  ]),
  ProvincePolygon('Limburg', [
    LatLng(51.4, 5.6),
    LatLng(51.4, 6.2),
    LatLng(50.7, 6.2),
    LatLng(50.7, 5.6),
  ]),
  ProvincePolygon('Noord-Brabant', [
    LatLng(51.8, 4.2),
    LatLng(51.8, 6.0),
    LatLng(51.3, 6.0),
    LatLng(51.3, 4.2),
  ]),
  ProvincePolygon('Noord-Holland', [
    LatLng(53.2, 4.5),
    LatLng(53.2, 5.5),
    LatLng(52.2, 5.5),
    LatLng(52.2, 4.5),
  ]),
  ProvincePolygon('Overijssel', [
    LatLng(53.1, 5.8),
    LatLng(53.1, 7.1),
    LatLng(52.2, 7.1),
    LatLng(52.2, 5.8),
  ]),
  ProvincePolygon('Utrecht', [
    LatLng(52.3, 4.9),
    LatLng(52.3, 5.7),
    LatLng(52.0, 5.7),
    LatLng(52.0, 4.9),
  ]),
  ProvincePolygon('Zeeland', [
    LatLng(51.7, 3.4),
    LatLng(51.7, 4.3),
    LatLng(51.3, 4.3),
    LatLng(51.3, 3.4),
  ]),
  ProvincePolygon('Zuid-Holland', [
    LatLng(52.3, 3.9),
    LatLng(52.3, 5.0),
    LatLng(51.8, 5.0),
    LatLng(51.8, 3.9),
  ]),
];

bool _pointInPolygon(LatLng point, List<LatLng> poly) {
  bool inside = false;
  for (int i = 0, j = poly.length - 1; i < poly.length; j = i++) {
    final xi = poly[i].latitude, yi = poly[i].longitude;
    final xj = poly[j].latitude, yj = poly[j].longitude;
    final intersect = ((yi > point.longitude) != (yj > point.longitude)) &&
        (point.latitude < (xj - xi) * (point.longitude - yi) / (yj - yi) + xi);
    if (intersect) inside = !inside;
  }
  return inside;
}

String _findProvince(double lat, double lon) {
  final point = LatLng(lat, lon);
  for (final province in _provinces) {
    if (_pointInPolygon(point, province.vertices)) {
      return province.name;
    }
  }
  return '';
}

String formatFriendlyLocation(double lat, double lon) {
  final area = _findProvince(lat, lon);
  final coords = '${lat.toStringAsFixed(3)}/${lon.toStringAsFixed(3)}';
  return area.isNotEmpty ? '$area $coords' : coords;
}