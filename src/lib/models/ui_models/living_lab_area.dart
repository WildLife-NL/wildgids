import 'package:latlong2/latlong.dart';

class LivingLabArea {
  final String id;
  final String name;
  final LatLng center;
  final double areaKm2;
  final List<LatLng> boundary;

  LivingLabArea({
    required this.id,
    required this.name,
    required this.center,
    required this.areaKm2,
    required this.boundary,
  });

  factory LivingLabArea.fromJson(Map<String, dynamic> json) {
    return LivingLabArea(
      id: json['id'],
      name: json['name'],
      center: LatLng(
        json['center']['lat'].toDouble(),
        json['center']['lng'].toDouble(),
      ),
      areaKm2: json['areaKm2'].toDouble(),
      boundary:
          (json['boundary'] as List<dynamic>)
              .map(
                (point) =>
                    LatLng(point['lat'].toDouble(), point['lng'].toDouble()),
              )
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'center': {'lat': center.latitude, 'lng': center.longitude},
      'areaKm2': areaKm2,
      'boundary':
          boundary
              .map((point) => {'lat': point.latitude, 'lng': point.longitude})
              .toList(),
    };
  }

  @override
  String toString() {
    return 'LivingLabArea(id: $id, name: $name, center: $center, areaKm2: $areaKm2, boundary: $boundary)';
  }
}
