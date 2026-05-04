import 'dart:convert';
import 'package:wildgids/data_managers/api_client.dart';
import 'package:wildgids/interfaces/data_apis/detections_api_interface.dart';
import 'package:wildgids/models/api_models/detection_pin.dart';

class DetectionsApi implements DetectionsApiInterface {
  final ApiClient apiClient;
  DetectionsApi(this.apiClient);

  @override
  Future<List<DetectionPin>> getAllDetections() async {
    final res = await apiClient.get('detections/', authenticated: true);

    if (res.statusCode == 200) {
      final body = res.body.trim();
      if (body.isEmpty) return const [];
      final data = json.decode(body);
      final list = (data is List) ? data : const [];
      return list
          .whereType<Map<String, dynamic>>()
          .map((m) => DetectionPin.fromJson(m))
          .toList();
    }

    if (res.statusCode == 204) return const [];
    throw Exception('Detections GET failed (${res.statusCode}): ${res.body}');
  }
}

