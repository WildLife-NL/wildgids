import 'dart:convert';
import 'package:wildrapport/data_managers/api_client.dart';
import 'package:wildrapport/interfaces/data_apis/interaction_query_api_interface.dart';
import 'package:wildrapport/models/api_models/interaction_query_result.dart';
import 'package:flutter/foundation.dart';

class InteractionQueryApi implements InteractionQueryApiInterface {
  final ApiClient apiClient;
  InteractionQueryApi(this.apiClient);

  @override
  Future<List<InteractionQueryResult>> queryInteractions({
    required double areaLatitude,
    required double areaLongitude,
    required int areaRadiusMeters,
    DateTime? momentAfter,
    DateTime? momentBefore,
  }) async {
    final params = <String, String>{
      'area_latitude' : areaLatitude.toString(),
      'area_longitude': areaLongitude.toString(),
      'area_radius'   : areaRadiusMeters.toString(),
      if (momentAfter  != null) 'moment_after' : momentAfter.toUtc().toIso8601String(),
      if (momentBefore != null) 'moment_before': momentBefore.toUtc().toIso8601String(),
    };

    const pathOnly = 'interactions/query/';

    // Build query safely
    final query = Uri(queryParameters: params).query;
    final pathWithQuery = '$pathOnly?$query';

    final res = await apiClient.get(pathWithQuery, authenticated: true);

    // Logs while debugging
    debugPrint('[IQ] GET $pathWithQuery => ${res.statusCode}');
    final preview = res.body.length > 300 ? res.body.substring(0, 300) : res.body;
    debugPrint('[IQ] body preview: ${preview.replaceAll('\n', ' ')}');

    if (res.statusCode == 200) {
      final body = res.body.trim();
      if (body.isEmpty) return const [];

      final decoded = json.decode(body);

      // API may return a raw array or wrap it
      final List list = decoded is List
          ? decoded
          : (decoded is Map && decoded['items'] is List) ? decoded['items'] : const [];

      return list
          .whereType<Map<String, dynamic>>()
          .map(InteractionQueryResult.fromJson)
          .toList();
    }

    if (res.statusCode == 204 || res.statusCode == 404) return const [];
    if (res.statusCode == 401) throw Exception('Unauthorized (401) on /interactions/query/');

    throw Exception('Query failed (${res.statusCode}): ${res.body}');
  }
}
