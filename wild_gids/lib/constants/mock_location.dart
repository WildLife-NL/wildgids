import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';

/// Global switch to mock location everywhere maps use current position.
class MockLocation {
  // Configurable mock toggle: defaults to true unless overridden via .env
  // Set MOCK_LOCATION=false in .env to use real GPS.
  static bool get enabled {
    final val = dotenv.maybeGet('MOCK_LOCATION');
    if (val == null || val.isEmpty) {
      // Default: mock enabled across all platforms
      return true;
    }
    final s = val.trim().toLowerCase();
    return s == 'true' || s == '1' || s == 'yes' || s == 'y';
  }
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
