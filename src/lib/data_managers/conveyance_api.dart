import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:wildgids/data_managers/api_client.dart';

class ConveyanceApi {
  final ApiClient client;
  ConveyanceApi(this.client);

  Future<List<Map<String, dynamic>>> getMyConveyances() async {
    debugPrint('[ConveyanceApi] ðŸ“¡ Fetching /conveyances/me');
    final res = await client.get('conveyances/me', authenticated: true);
    debugPrint('[ConveyanceApi] Response status: ${res.statusCode}');
    debugPrint('[ConveyanceApi] Response body: ${res.body}');

    if (res.statusCode != 200) {
      debugPrint(
        '[ConveyanceApi] âŒ Failed to fetch conveyances: ${res.statusCode}',
      );
      throw Exception(
        'Failed to fetch conveyances: ${res.statusCode} ${res.body}',
      );
    }

    final decoded = jsonDecode(res.body);
    debugPrint('[ConveyanceApi] Decoded type: ${decoded.runtimeType}');

    if (decoded is List) {
      debugPrint(
        '[ConveyanceApi] âœ“ Found ${decoded.length} conveyances in list',
      );
      return List<Map<String, dynamic>>.from(decoded);
    } else if (decoded is Map && decoded['conveyances'] is List) {
      final conveyances = List<Map<String, dynamic>>.from(
        decoded['conveyances'],
      );
      debugPrint(
        '[ConveyanceApi] âœ“ Found ${conveyances.length} conveyances in map',
      );
      return conveyances;
    }

    debugPrint('[ConveyanceApi] âš ï¸ No conveyances found, returning empty list');
    return [];
  }
}

