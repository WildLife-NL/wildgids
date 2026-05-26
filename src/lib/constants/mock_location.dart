import 'package:geolocator/geolocator.dart';

/// Vaste testlocatie voor GPS in de hele app (kaart, tracking, waarneming).
class MockLocation {
  /// Zet op `false` om weer echte GPS te gebruiken.
  static const bool enabled = true;

  /// Eindhoven-omgeving (jouw coördinaten).
  static const double lat = 51.42611;
  static const double lon = 5.48261;

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

  static Future<Position> current({
    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
    ),
  }) async {
    if (enabled) return position();
    return Geolocator.getCurrentPosition(locationSettings: locationSettings);
  }
}
