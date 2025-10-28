import 'dart:convert';
import 'package:wildrapport/data_managers/api_client.dart';
import 'package:wildrapport/interfaces/data_apis/tracking_api_interface.dart';

class TrackingApi implements TrackingApiInterface {
  final ApiClient client;
  TrackingApi(this.client);

  @override
  Future<void> addTrackingReading({
    required double lat,
    required double lon,
    required DateTime timestampUtc,
  }) async {
    // Build request body EXACTLY like the /tracking-reading/ docs:
    // {
    //   "location": { "latitude": ..., "longitude": ... },
    //   "timestamp": "2025-10-22T12:00:00Z"
    // }
    final body = {
      "location": {
        "latitude": lat,
        "longitude": lon,
      },
      "timestamp": timestampUtc.toUtc().toIso8601String(),
    };

    // Your ApiClient.post works like ApiClient.put in ProfileApi:
    // path, bodyMap, authenticated: true
    final res = await client.post(
      '/tracking-reading/',
      body,
      authenticated: true,
    );

    // We expect 2xx = success
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        '[TrackingApi] Failed (${res.statusCode}): ${res.body}',
      );
    }

    // Optional: backend might include a message/advice in the response:
    // We don't surface it in UI yet, but we can log it.
    if (res.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(res.body);
        final msg = decoded['message']?.toString();
        if (msg != null && msg.isNotEmpty) {
          // ignore: avoid_print
          print('[TrackingApi] server message: $msg');
        }
      } catch (_) {
        // Response wasn't JSON or didn't have message -> ignore
      }
    }
  }
}
