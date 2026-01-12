import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Global switch to mock location everywhere maps use current position.
class MockLocation {
  // Enable mock location only on web builds to aid development.
  // Mobile (Android/iOS) will use real GPS by default.
  static bool get enabled => kIsWeb;
  static const double lat = 52.088130;
  static const double lon = 5.170465;

  /// Create a Position with our mocked coordinates using reasonable defaults.
  static Position position() => Position(
        latitude: lat,
        longitude: lon,
        timestamp: DateTime.now(),
        accuracy: 5,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
}
