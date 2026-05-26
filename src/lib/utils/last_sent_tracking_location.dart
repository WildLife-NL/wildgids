import 'package:geolocator/geolocator.dart';
import 'package:wildgids/constants/location_sharing_config.dart';

/// Remembers the last coordinates sent to POST `/tracking-reading/`.
///
/// Skips redundant pings when the device has not moved meaningfully since the
/// last successful send (saves bandwidth and battery).
class LastSentTrackingLocation {
  LastSentTrackingLocation._();

  static double? _latitude;
  static double? _longitude;

  static bool get hasSent => _latitude != null && _longitude != null;

  /// `true` when [lat]/[lon] are within [LocationSharingConfig.minDistanceMetersForNewPing] of the last send.
  static bool isUnchanged(double lat, double lon) {
    if (_latitude == null || _longitude == null) return false;
    final distance = Geolocator.distanceBetween(
      _latitude!,
      _longitude!,
      lat,
      lon,
    );
    return distance < LocationSharingConfig.minDistanceMetersForNewPing;
  }

  static void record(double lat, double lon) {
    _latitude = lat;
    _longitude = lon;
  }

  static void clear() {
    _latitude = null;
    _longitude = null;
  }
}
