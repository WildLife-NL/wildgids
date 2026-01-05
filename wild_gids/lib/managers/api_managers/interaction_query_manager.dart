import 'dart:math' as math;
import 'package:wildgids/interfaces/data_apis/interaction_query_api_interface.dart';
import 'package:wildgids/models/api_models/interaction_query_result.dart';

/// Thin service that normalizes inputs (radius, time window)
/// before delegating to the API.
class InteractionQueryManager {
  final InteractionQueryApiInterface api;

  InteractionQueryManager(this.api);

  /// Load interactions near a point.
  ///
  /// - `radiusMeters` will be clamped to [250, 20000] for sane queries.
  /// - If `after`/`before` are null, defaults to the **last 7 days** in UTC.
  Future<List<InteractionQueryResult>> loadNearby({
    required double lat,
    required double lon,
    int radiusMeters = 1500,
    DateTime? after,
    DateTime? before,
  }) async {
    final clampedRadius = radiusMeters.clamp(250, 20000);

    final nowUtc = DateTime.now().toUtc();
    final normalizedAfter =
        (after ?? nowUtc.subtract(const Duration(days: 365))).toUtc();
    final normalizedBefore = (before ?? nowUtc).toUtc();

    return api.queryInteractions(
      areaLatitude: lat,
      areaLongitude: lon,
      areaRadiusMeters: clampedRadius,
      momentAfter: normalizedAfter,
      momentBefore: normalizedBefore,
    );
  }

  /// Convenience: derive a *rough* radius (in meters) from map zoom + latitude.
  /// Use half the screen width in pixels to estimate the visible radius.
  ///
  /// `zoom`   â€“ current map zoom (e.g., 5..18)
  /// `lat`    â€“ map center latitude (affects meters-per-pixel)
  /// `widthPx`â€“ screen width in pixels (defaults to 400 if unknown)
  ///
  /// Returns a clamped value in [250, 20000].
  int radiusFromZoom({
    required double zoom,
    required double lat,
    double widthPx = 400,
  }) {
    // Web Mercator meters-per-pixel at given latitude/zoom.
    final metersPerPixel =
        156543.03392 * math.cos(lat * math.pi / 180.0) / math.pow(2.0, zoom);
    final halfWidthMeters = (widthPx / 2.0) * metersPerPixel;
    final radius = halfWidthMeters.round();
    return radius.clamp(250, 20000);
  }
}

