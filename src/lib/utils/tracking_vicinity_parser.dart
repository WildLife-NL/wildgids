import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_pin.dart';
import 'package:wildgids/models/api_models/detection_pin.dart';
import 'package:wildgids/models/api_models/interaction_query_result.dart';
import 'package:wildgids/models/api_models/vicinity.dart';

/// Parses animals/detections/interactions from tracking-reading API responses.
class TrackingVicinityParser {
  TrackingVicinityParser._();

  static const double defaultMaxDistanceFromReadingMeters = 12000;

  static void logHttpResponse({
    required String tag,
    required String endpoint,
    required int statusCode,
    required String body,
  }) {
    final preview = body.length > 500 ? '${body.substring(0, 500)}...' : body;
    debugPrint('[$tag] $endpoint => $statusCode (body ${body.length} chars)');
    if (preview.isNotEmpty) {
      debugPrint('[$tag] body preview: $preview');
    }
  }

  static void logVicinityCounts(String tag, Vicinity vicinity) {
    debugPrint(
      '[$tag] parsed animals=${vicinity.animals.length} '
      'detections=${vicinity.detections.length} '
      'interactions=${vicinity.interactions.length}',
    );
  }

  static Map<String, dynamic> unwrapVicinityPayload(Map<String, dynamic> data) {
    final nested = data['vicinity'];
    if (nested is Map<String, dynamic>) {
      return nested;
    }
    if (nested is Map) {
      return Map<String, dynamic>.from(nested);
    }
    return data;
  }

  static Vicinity empty() =>
      Vicinity(animals: [], detections: [], interactions: []);

  static Vicinity? vicinityFromReadingJson(Map<String, dynamic> decoded) {
    if (decoded['vicinity'] is Map ||
        decoded['animals'] != null ||
        decoded['detections'] != null ||
        decoded['interactions'] != null) {
      final payload = unwrapVicinityPayload(decoded);
      return Vicinity.fromJson(payload);
    }
    return null;
  }

  static Vicinity parseResponseBody(
    String body, {
    required String tag,
    required String endpoint,
  }) {
    if (body.trim().isEmpty) {
      logVicinityCounts(tag, empty());
      return empty();
    }

    final decoded = json.decode(body);
    if (decoded is List) {
      return vicinityFromReadingsList(decoded, tag: tag);
    }

    if (decoded is Map<String, dynamic>) {
      final vicinity = vicinityFromReadingJson(decoded) ?? empty();
      logVicinityCounts(tag, vicinity);
      return vicinity;
    }

    if (decoded is Map) {
      final vicinity =
          vicinityFromReadingJson(Map<String, dynamic>.from(decoded)) ??
              empty();
      logVicinityCounts(tag, vicinity);
      return vicinity;
    }

    throw FormatException(
      '$tag $endpoint: expected JSON object or array, got ${decoded.runtimeType}',
    );
  }

  /// Merges pins from all tracking readings returned by the API.
  ///
  /// The API already returns animals/detections/interactions in the vicinity of
  /// each reading; do not apply client-side age or distance filters here.
  static Vicinity vicinityFromReadingsList(
    List<dynamic> readings, {
    String tag = 'TrackingVicinityParser',
  }) {
    final maps = readings
        .whereType<Map>()
        .map((e) => e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e))
        .toList();
    if (maps.isEmpty) return empty();

    var merged = empty();
    var readingsUsed = 0;

    for (final reading in maps) {
      final raw = vicinityFromReadingJson(reading);
      if (raw == null) continue;

      merged = merge(merged, raw);
      readingsUsed++;
    }

    debugPrint(
      '[$tag] Merged $readingsUsed tracking reading(s): '
      '${merged.animals.length} animals, '
      '${merged.detections.length} detections, '
      '${merged.interactions.length} interactions',
    );
    logVicinityCounts(tag, merged);
    return merged;
  }

  /// Combines two vicinities, deduplicating by entity id.
  static Vicinity merge(Vicinity a, Vicinity b) {
    if (a.animals.isEmpty &&
        a.detections.isEmpty &&
        a.interactions.isEmpty) {
      return b;
    }
    if (b.animals.isEmpty &&
        b.detections.isEmpty &&
        b.interactions.isEmpty) {
      return a;
    }

    final animalIds = <String>{};
    final animals = <AnimalPin>[];
    for (final pin in [...a.animals, ...b.animals]) {
      if (animalIds.add(pin.id)) animals.add(pin);
    }

    final detectionIds = <String>{};
    final detections = <DetectionPin>[];
    for (final pin in [...a.detections, ...b.detections]) {
      if (detectionIds.add(pin.id)) detections.add(pin);
    }

    final interactionKeys = <String>{};
    final interactions = <InteractionQueryResult>[];
    for (final pin in [...a.interactions, ...b.interactions]) {
      if (interactionKeys.add(pin.dedupeKey)) interactions.add(pin);
    }

    return Vicinity(
      animals: animals,
      detections: detections,
      interactions: interactions,
    );
  }

  static bool isEmpty(Vicinity v) =>
      v.animals.isEmpty && v.detections.isEmpty && v.interactions.isEmpty;

  static Map<String, dynamic>? latestReadingMap(List<dynamic> readings) {
    Map<String, dynamic>? latest;
    DateTime? latestTime;

    for (final item in readings) {
      if (item is! Map) continue;
      final map = item is Map<String, dynamic>
          ? item
          : Map<String, dynamic>.from(item);

      final tsRaw = map['timestamp']?.toString();
      final parsed = tsRaw != null ? DateTime.tryParse(tsRaw) : null;
      if (latest == null) {
        latest = map;
        latestTime = parsed;
        continue;
      }
      if (parsed != null &&
          (latestTime == null || parsed.isAfter(latestTime))) {
        latest = map;
        latestTime = parsed;
      }
    }

    return latest;
  }

  static ({double latitude, double longitude})? readingLocation(
    Map<String, dynamic> reading,
  ) {
    final location = reading['location'];
    if (location is! Map) return null;
    final map = location is Map<String, dynamic>
        ? location
        : Map<String, dynamic>.from(location);
    final lat = _asDouble(map['latitude'] ?? map['lat']);
    final lon = _asDouble(map['longitude'] ?? map['lon']);
    if (lat == null || lon == null) return null;
    return (latitude: lat, longitude: lon);
  }

  static Vicinity filterNearReading(
    Vicinity vicinity,
    double readingLat,
    double readingLon, {
    double maxMeters = defaultMaxDistanceFromReadingMeters,
    String tag = 'TrackingVicinityParser',
  }) {
    bool near(double lat, double lon, String kind, String id) {
      final meters = Geolocator.distanceBetween(
        readingLat,
        readingLon,
        lat,
        lon,
      );
      if (meters > maxMeters) {
        debugPrint(
          '[$tag] dropped $kind $id: ${meters.toStringAsFixed(0)}m from reading',
        );
        return false;
      }
      return true;
    }

    final filtered = Vicinity(
      animals: vicinity.animals
          .where((a) => near(a.lat, a.lon, 'animal', a.id))
          .toList(),
      detections: vicinity.detections
          .where((d) => near(d.lat, d.lon, 'detection', d.id))
          .toList(),
      interactions: vicinity.interactions
          .where(
            (i) => _interactionNearReading(
              i,
              readingLat,
              readingLon,
              maxMeters,
              near,
            ),
          )
          .toList(),
    );

    return filtered;
  }

  /// Uses [InteractionQueryResult.eventLat]/[eventLon] (place) when set — matches
  /// "where it happened". Falls back to report GPS only without a place.
  static bool _interactionNearReading(
    InteractionQueryResult interaction,
    double readingLat,
    double readingLon,
    double maxMeters,
    bool Function(double lat, double lon, String kind, String id) near,
  ) {
    if (interaction.eventLat != null && interaction.eventLon != null) {
      return near(
        interaction.eventLat!,
        interaction.eventLon!,
        'interaction',
        interaction.id,
      );
    }
    if (interaction.reportLat != null && interaction.reportLon != null) {
      return near(
        interaction.reportLat!,
        interaction.reportLon!,
        'interaction',
        interaction.id,
      );
    }
    return near(interaction.lat, interaction.lon, 'interaction', interaction.id);
  }

  static double? _asDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
