import 'dart:convert';
import 'package:wildgids/data_managers/api_client.dart';
import 'package:wildgids/interfaces/data_apis/interaction_types_api_interface.dart';
import 'package:wildgids/models/api_models/interaction_type.dart';
import 'package:flutter/foundation.dart';

class InteractionTypesApi implements InteractionTypesApiInterface {
  final ApiClient apiClient;
  InteractionTypesApi(this.apiClient);

  @override
  Future<List<InteractionType>> getAllInteractionTypes() async {
    // Attempt to get interaction types from server. The exact endpoint
    // may vary across deployments; try a reasonable path and return an
    // empty list on non-200/204 responses.
    const path = 'interactionTypes/';
    try {
      // First try authenticated (if token exists, header will be included).
      var res = await apiClient.get(path, authenticated: true);
      debugPrint('[InteractionTypesApi] GET $path => ${res.statusCode}');
      if (res.statusCode == 401 || res.statusCode == 403) {
        // If unauthorized, retry without auth in case the endpoint allows anonymous access.
        debugPrint('[InteractionTypesApi] Unauthorized, retrying without auth');
        res = await apiClient.get(path, authenticated: false);
        debugPrint('[InteractionTypesApi] (retry) GET $path => ${res.statusCode}');
      }

      if (res.statusCode == 200) {
        final body = res.body.trim();
        if (body.isEmpty) return const [];
        final decoded = json.decode(body);
        final List list =
            decoded is List
                ? decoded
                : (decoded is Map && decoded['items'] is List)
                ? decoded['items']
                : const [];
        return list
            .whereType<Map<String, dynamic>>()
            .map(InteractionType.fromJson)
            .toList();
      }
      if (res.statusCode == 204 || res.statusCode == 404) return const [];
    } catch (e) {
      debugPrint('[InteractionTypesApi] Error fetching types: $e');
    }

    return const [];
  }
}

