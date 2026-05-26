import 'package:wildgids/models/api_models/vicinity.dart';

/// Map vicinity from tracking-reading endpoints (OpenAPI TrackingReading schema).
abstract class VicinityApiInterface {
  /// Latest reading from GET /tracking-readings/me/.
  Future<Vicinity> getMyVicinity();

  /// POST /tracking-reading/ for the current coordinates.
  Future<Vicinity> getVicinityForCurrentLocation({
    required double latitude,
    required double longitude,
    DateTime? timestamp,
  });

  Future<Vicinity> submitTrackingReading({
    required double latitude,
    required double longitude,
    DateTime? timestamp,
  });
}
