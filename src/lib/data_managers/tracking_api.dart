import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:wildgids/data_managers/api_client.dart';
import 'package:wildgids/interfaces/data_apis/tracking_api_interface.dart';
import 'package:wildgids/utils/tracking_reading_timestamp.dart';
import 'package:wildgids/utils/tracking_vicinity_parser.dart';

class TrackingApi implements TrackingApiInterface {
  TrackingApi(this.client);

  final ApiClient client;

  @override
  Future<TrackingNotice?> addTrackingReading({
    required double lat,
    required double lon,
    required DateTime timestampUtc,
  }) async {
    var ts = TrackingReadingTimestamp.forRequest(preferred: timestampUtc);

    var res = await _postTrackingReading(lat: lat, lon: lon, timestamp: ts);

    if (TrackingReadingTimestamp.isTimestampValidationError(
      res.statusCode,
      res.body,
    )) {
      final serverNow =
          TrackingReadingTimestamp.parseServerNowFromErrorBody(res.body);
      if (serverNow != null) {
        ts = TrackingReadingTimestamp.beforeServerNow(serverNow);
        debugPrint(
          '[TrackingApi] retrying POST with server-adjusted timestamp '
          '${ts.toIso8601String()}',
        );
        res = await _postTrackingReading(lat: lat, lon: lon, timestamp: ts);
      }
    }

    TrackingVicinityParser.logHttpResponse(
      tag: 'TrackingApi',
      endpoint: 'POST /tracking-reading/',
      statusCode: res.statusCode,
      body: res.body,
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      debugPrint('[TrackingApi] ERROR - Status ${res.statusCode}: ${res.body}');
      throw Exception('[TrackingApi] Failed (${res.statusCode}): ${res.body}');
    }

    try {
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      final vicinity = TrackingVicinityParser.vicinityFromReadingJson(decoded);

      final conv = decoded['conveyance'];
      final msgObj = conv is Map ? conv['message'] : null;

      final msgText1 = (msgObj is Map ? msgObj['text'] : null)?.toString();
      final sev1 =
          msgObj is Map && msgObj['severity'] is num
              ? (msgObj['severity'] as num).toInt()
              : null;

      if ((msgText1 != null && msgText1.isNotEmpty) || vicinity != null) {
        if (msgText1 != null && msgText1.isNotEmpty) {
          debugPrint('[TrackingApi] Message received: "$msgText1"');
        }
        return TrackingNotice(
          msgText1 ?? '',
          severity: sev1,
          vicinity: vicinity,
        );
      }
    } catch (e) {
      debugPrint('[TrackingApi] Error parsing POST response: $e');
    }

    return null;
  }

  Future<dynamic> _postTrackingReading({
    required double lat,
    required double lon,
    required DateTime timestamp,
  }) {
    return client.post(
      '/tracking-reading/',
      {
        'location': {'latitude': lat, 'longitude': lon},
        'timestamp': timestamp.toUtc().toIso8601String(),
      },
      authenticated: true,
    );
  }

  @override
  Future<List<TrackingReadingResponse>> getMyTrackingReadings() async {
    final res = await client.get('/tracking-readings/me/', authenticated: true);

    TrackingVicinityParser.logHttpResponse(
      tag: 'TrackingApi',
      endpoint: 'GET /tracking-readings/me/',
      statusCode: res.statusCode,
      body: res.body,
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('[TrackingApi] Failed (${res.statusCode}): ${res.body}');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! List) {
      throw FormatException(
        'Expected JSON array from /tracking-readings/me/, got ${decoded.runtimeType}',
      );
    }

    return decoded
        .whereType<Map>()
        .map(
          (e) => TrackingReadingResponse.fromJson(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList();
  }
}
