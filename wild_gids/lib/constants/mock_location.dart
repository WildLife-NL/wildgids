import 'package:geolocator/geolocator.dart';

/// Global switch to mock location everywhere maps use current position.
class MockLocation {
  static const bool enabled = true;
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
