import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:wildrapport/data_managers/api_client.dart';
import 'package:wildrapport/interfaces/data_apis/vicinity_api_interface.dart';
import 'package:wildrapport/models/api_models/vicinity.dart';

class VicinityApi implements VicinityApiInterface {
  final ApiClient apiClient;
  VicinityApi(this.apiClient);

  @override
  Future<Vicinity> getMyVicinity() async {
    final res = await apiClient.get('vicinity/me', authenticated: true);

    debugPrint('[VicinityApi] GET vicinity/me => ${res.statusCode}');

    if (res.statusCode == 200) {
      final body = res.body.trim();
      debugPrint('[VicinityApi] Response body length: ${body.length}');
      debugPrint(
        '[VicinityApi] Raw response: ${body.substring(0, body.length > 500 ? 500 : body.length)}...',
      );

      if (body.isEmpty) {
        debugPrint(
          '[VicinityApi] Empty response body, returning empty vicinity',
        );
        return Vicinity(animals: [], detections: [], interactions: []);
      }

      final data = json.decode(body) as Map<String, dynamic>;
      debugPrint(
        '[VicinityApi] Parsed JSON - animals: ${(data['animals'] as List?)?.length ?? 0}, '
        'detections: ${(data['detections'] as List?)?.length ?? 0}, '
        'interactions: ${(data['interactions'] as List?)?.length ?? 0}',
      );

      final vicinity = Vicinity.fromJson(data);
      debugPrint(
        '[VicinityApi] Created Vicinity object - animals: ${vicinity.animals.length}, '
        'detections: ${vicinity.detections.length}, '
        'interactions: ${vicinity.interactions.length}',
      );

      return vicinity;
    }

    if (res.statusCode == 204) {
      debugPrint('[VicinityApi] 204 No Content, returning empty vicinity');
      return Vicinity(animals: [], detections: [], interactions: []);
    }

    debugPrint('[VicinityApi] Error response: ${res.body}');
    throw Exception('Vicinity GET failed (${res.statusCode}): ${res.body}');
  }
}
