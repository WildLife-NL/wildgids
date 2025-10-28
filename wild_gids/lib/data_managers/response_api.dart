import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

import 'package:wildrapport/data_managers/api_client.dart';
import 'package:wildrapport/interfaces/data_apis/response_api_interface.dart';

class ResponseApi implements ResponseApiInterface {
  final ApiClient client;
  ResponseApi(this.client);

  final greenLog = '\x1B[32m';
  final redLog = '\x1B[31m';
  final yellowLog = '\x1B[93m';

  @override
  Future<bool> addReponse(
    String interactionID,
    String questionID,
    String? answerID,
    String? text,
  ) async {
    // Log the payload being sent
    final payload = {
      "answerID": answerID,
      "interactionID": interactionID,
      "questionID": questionID,
      "text": text,
    };
    
    debugPrint("$yellowLog [ResponseApi]: Sending response...");
    debugPrint("$yellowLog [ResponseApi]: Payload: $payload");
    
    http.Response response = await client.post('response/', payload, authenticated: true);

    debugPrint("$yellowLog [ResponseApi]: Response status: ${response.statusCode}");
    debugPrint("$yellowLog [ResponseApi]: Response body: ${response.body}");
    
    if (response.statusCode == HttpStatus.ok || response.statusCode == HttpStatus.created) {
      debugPrint("$greenLog [ResponseApi]: Answer submitted successfully (${response.statusCode})");
      return true;
    } else {
      debugPrint(
        "$redLog [ResponseApi]: Answer could NOT be submitted, status code: ${response.statusCode}",
      );
      debugPrint("$redLog [ResponseApi]: Response body: ${response.body}");
      return false;
    }
  }
}
