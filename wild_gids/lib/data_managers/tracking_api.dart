import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:wildrapport/data_managers/api_client.dart';
import 'package:wildrapport/interfaces/data_apis/tracking_api_interface.dart';

class TrackingApi implements TrackingApiInterface {
  final ApiClient client;
  TrackingApi(this.client);

  @override
  Future<TrackingNotice?> addTrackingReading({
    required double lat,
    required double lon,
    required DateTime timestampUtc,
  }) async {
    // Reduced logging - only log errors or messages
    // debugPrint('[TrackingApi] Sending location: $lat, $lon at ${timestampUtc.toIso8601String()}');

    // Build request body EXACTLY like the /tracking-reading/ docs:
    // {
    //   "location": { "latitude": ..., "longitude": ... },
    //   "timestamp": "2025-10-22T12:00:00Z"
    // }
    final body = {
      "location": {"latitude": lat, "longitude": lon},
      "timestamp": timestampUtc.toUtc().toIso8601String(),
    };

    // Your ApiClient.post works like ApiClient.put in ProfileApi:
    // path, bodyMap, authenticated: true
    final res = await client.post(
      '/tracking-reading/',
      body,
      authenticated: true,
    );

    // Only log non-success responses
    if (res.statusCode < 200 || res.statusCode >= 300) {
      debugPrint('[TrackingApi] Response status: ${res.statusCode}');
      debugPrint('[TrackingApi] ERROR - Status ${res.statusCode}: ${res.body}');
      throw Exception('[TrackingApi] Failed (${res.statusCode}): ${res.body}');
    }

    // Try to extract an optional message from the response
    try {
      final Map<String, dynamic> decoded = jsonDecode(res.body);

      // Preferred shape: conveyance.message.text (+ optional severity)
      final conv = decoded['conveyance'];
      final msgObj = conv?['message'];

      final msgText1 = (msgObj is Map ? msgObj['text'] : null)?.toString();
      final sev1 =
          msgObj is Map && msgObj['severity'] is num
              ? (msgObj['severity'] as num).toInt()
              : null;

      if (msgText1 != null && msgText1.isNotEmpty) {
        debugPrint('[TrackingApi] Message received: "$msgText1"');
        return TrackingNotice(msgText1, severity: sev1);
      }

      // Fallbacks: { "message": "..." } or { "message": { "text": "..." } }
      final message = decoded['message'];
      if (message is String && message.isNotEmpty) {
        debugPrint('[TrackingApi] Message received: "$message"');
        return TrackingNotice(message);
      }
      if (message is Map && (message['text']?.toString().isNotEmpty ?? false)) {
        final sev2 =
            message['severity'] is num
                ? (message['severity'] as num).toInt()
                : null;
        debugPrint('[TrackingApi] Message received: "${message['text']}"');
        return TrackingNotice(message['text'].toString(), severity: sev2);
      }

      // Only log when messages are expected but missing
      // debugPrint('[TrackingApi] No message found in response');
    } catch (e) {
      debugPrint('[TrackingApi] Error parsing message: $e');
      // Non-JSON or unexpected shape → no notice
    }

    return null; // success, but no message to show
  }

  @override
  Future<List<TrackingReadingResponse>> getMyTrackingReadings() async {
    final res = await client.get('/tracking-readings/me', authenticated: true);
    
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('[TrackingApi] Failed (${res.statusCode}): ${res.body}');
    }
    
    try {
      final List<dynamic> jsonList = jsonDecode(res.body);
      final result = jsonList
          .map((json) => TrackingReadingResponse.fromJson(json as Map<String, dynamic>))
          .toList();
      return result;
    } catch (e) {
      rethrow;
    }
  }
}
