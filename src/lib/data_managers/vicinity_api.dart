import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:wildgids/data_managers/api_client.dart';
import 'package:wildgids/interfaces/data_apis/vicinity_api_interface.dart';
import 'package:wildgids/models/api_models/vicinity.dart';
import 'package:wildgids/utils/tracking_reading_timestamp.dart';
import 'package:wildgids/utils/tracking_vicinity_parser.dart';

/// Loads map pins from tracking-reading API (not /vicinity/me).
class VicinityApi implements VicinityApiInterface {
  VicinityApi(this.apiClient);

  final ApiClient apiClient;

  static const String _tag = 'VicinityApi';
  static const String _getMyReadingsPath = '/tracking-readings/me/';
  static const String _postReadingPath = '/tracking-reading/';

  @override
  Future<Vicinity> getMyVicinity() async {
    final res = await apiClient.get(_getMyReadingsPath, authenticated: true);
    TrackingVicinityParser.logHttpResponse(
      tag: _tag,
      endpoint: 'GET $_getMyReadingsPath',
      statusCode: res.statusCode,
      body: res.body,
    );

    if (res.statusCode == 204) {
      return TrackingVicinityParser.empty();
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        '[$_tag] GET $_getMyReadingsPath failed (${res.statusCode}): ${res.body}',
      );
    }

    final decoded = _decodeBody(res.body);
    if (decoded is List) {
      return TrackingVicinityParser.vicinityFromReadingsList(
        decoded,
        tag: _tag,
      );
    }

    return TrackingVicinityParser.parseResponseBody(
      res.body,
      tag: _tag,
      endpoint: 'GET $_getMyReadingsPath',
    );
  }

  @override
  Future<Vicinity> getVicinityForCurrentLocation({
    required double latitude,
    required double longitude,
    DateTime? timestamp,
  }) =>
      submitTrackingReading(
        latitude: latitude,
        longitude: longitude,
        timestamp: timestamp,
      );

  @override
  Future<Vicinity> submitTrackingReading({
    required double latitude,
    required double longitude,
    DateTime? timestamp,
  }) async {
    var ts = TrackingReadingTimestamp.forRequest(preferred: timestamp);

    var res = await _postTrackingReading(
      latitude: latitude,
      longitude: longitude,
      timestamp: ts,
    );

    if (TrackingReadingTimestamp.isTimestampValidationError(
      res.statusCode,
      res.body,
    )) {
      final serverNow =
          TrackingReadingTimestamp.parseServerNowFromErrorBody(res.body);
      if (serverNow != null) {
        ts = TrackingReadingTimestamp.beforeServerNow(serverNow);
        debugPrint(
          '[$_tag] retrying POST with server-adjusted timestamp '
          '${ts.toIso8601String()}',
        );
        res = await _postTrackingReading(
          latitude: latitude,
          longitude: longitude,
          timestamp: ts,
        );
      }
    }

    TrackingVicinityParser.logHttpResponse(
      tag: _tag,
      endpoint: 'POST $_postReadingPath',
      statusCode: res.statusCode,
      body: res.body,
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        '[$_tag] POST $_postReadingPath failed (${res.statusCode}): ${res.body}',
      );
    }

    return TrackingVicinityParser.parseResponseBody(
      res.body,
      tag: _tag,
      endpoint: 'POST $_postReadingPath',
    );
  }

  Future<dynamic> _postTrackingReading({
    required double latitude,
    required double longitude,
    required DateTime timestamp,
  }) {
    return apiClient.post(
      _postReadingPath,
      {
        'location': {'latitude': latitude, 'longitude': longitude},
        'timestamp': timestamp.toUtc().toIso8601String(),
      },
      authenticated: true,
    );
  }

  Object? _decodeBody(String body) {
    if (body.trim().isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }
}
