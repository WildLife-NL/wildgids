import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:wildrapport/data_managers/api_client.dart';
import 'package:wildrapport/models/api_models/my_interaction.dart';

class MyInteractionApi {
  final ApiClient client;
  final greenLog = '\x1B[32m';
  final redLog = '\x1B[31m';
  final yellowLog = '\x1B[93m';

  MyInteractionApi(this.client);

  /// Fetches the user's interaction history from the GET /interactions/me endpoint
  Future<List<MyInteraction>> getMyInteractions() async {
    try {
      debugPrint("$yellowLog[MyInteractionApi]: Fetching my interactions");

      http.Response response = await client.get(
        'interactions/me/',
        authenticated: true,
      );

      debugPrint(
        "$yellowLog[MyInteractionApi]: Response status: ${response.statusCode}",
      );

      if (response.statusCode == HttpStatus.ok) {
        final List<dynamic> json = jsonDecode(response.body);
        debugPrint(
          "$greenLog[MyInteractionApi]: Successfully fetched ${json.length} interactions",
        );

        List<MyInteraction> interactions =
            json
                .map((e) => MyInteraction.fromJson(e as Map<String, dynamic>))
                .toList();

        return interactions;
      } else {
        debugPrint(
          "$redLog[MyInteractionApi]: Failed to fetch interactions: ${response.statusCode}",
        );
        debugPrint(
          "$redLog[MyInteractionApi]: Response body: ${response.body}",
        );
        throw Exception(
          "Failed to get my interactions: ${response.statusCode}",
        );
      }
    } catch (e) {
      debugPrint("$redLog[MyInteractionApi]: Error fetching interactions: $e");
      rethrow;
    }
  }
}
