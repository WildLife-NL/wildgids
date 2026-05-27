import 'package:wildgids/models/api_models/vicinity.dart';

/// Map pins from tracking-reading endpoints (OpenAPI TrackingReading schema).
abstract class TrackingReadingsApiInterface {
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

/// Backward-compatible alias while names are migrated.
typedef VicinityApiInterface = TrackingReadingsApiInterface;
