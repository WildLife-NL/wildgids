import 'package:latlong2/latlong.dart';

class PolygonArea {
  final List<LatLng> points;
  final String areaType; // 'polygon' or 'gps_recording'
  
  PolygonArea({
    required this.points,
    this.areaType = 'polygon',
  });

  /// Calculate area in square meters using Shoelace formula
  double calculateAreaInSquareMeters() {
    if (points.length < 3) return 0.0;

    double area = 0.0;
    for (int i = 0; i < points.length; i++) {
      final LatLng p1 = points[i];
      final LatLng p2 = points[(i + 1) % points.length];
      
      // Using simplified haversine-based calculation
      area += (p2.longitude - p1.longitude) * 
              (p2.latitude + p1.latitude);
    }
    
    area = (area.abs() / 2);
    
    // Convert to approximate square meters at equator
    // More precise calculation would use proper GIS library
    const double metersPerDegree = 111320.0;
    return area * metersPerDegree * metersPerDegree;
  }

  /// Calculate area in hectares
  double getAreaInHectares() {
    return calculateAreaInSquareMeters() / 10000;
  }

  /// Get center point of polygon
  LatLng getCenterPoint() {
    if (points.isEmpty) {
      return const LatLng(0, 0);
    }
    
    double sumLat = 0;
    double sumLng = 0;
    
    for (final point in points) {
      sumLat += point.latitude;
      sumLng += point.longitude;
    }
    
    return LatLng(
      sumLat / points.length,
      sumLng / points.length,
    );
  }

  Map<String, dynamic> toJson() => {
    'points': points.map((p) => {
      'latitude': p.latitude,
      'longitude': p.longitude,
    }).toList(),
    'areaType': areaType,
    'areaSquareMeters': calculateAreaInSquareMeters(),
    'areaHectares': getAreaInHectares(),
  };

  factory PolygonArea.fromJson(Map<String, dynamic> json) => PolygonArea(
    points: (json['points'] as List)
        .map((p) => LatLng(p['latitude'] as double, p['longitude'] as double))
        .toList(),
    areaType: json['areaType'] ?? 'polygon',
  );
}
