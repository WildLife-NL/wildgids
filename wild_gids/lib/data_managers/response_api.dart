import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

import 'package:wildrapport/data_managers/api_client.dart';
import 'package:wildrapport/interfaces/data_apis/response_api_interface.dart';
import 'package:wildrapport/models/api_models/my_response.dart';
import 'dart:convert';

class ResponseApi implements ResponseApiInterface {
  final ApiClient client;
  ResponseApi(this.client);

  final greenLog = '\x1B[32m';
  final redLog = '\x1B[31m';
  final yellowLog = '\x1B[93m';

  @override
  Future<ResponseSubmissionResult> addReponse(
    String interactionID,
    String questionID,
    String? answerID,
    String? text,
  ) async {
    // Log the payload being sent
    final trimmedText = text?.trim();
    final payload = {
      "answerID": answerID,
      "interactionID": interactionID,
      "questionID": questionID,
      // Avoid sending empty strings; backend regexes often reject them
      "text": (trimmedText == null || trimmedText.isEmpty) ? null : trimmedText,
    };
    debugPrint("$yellowLog========================================");
    debugPrint("$yellowLog [ResponseApi]: SENDING RESPONSE TO BACKEND");
    debugPrint("$yellowLog [ResponseApi]: Endpoint: POST /response/");
    debugPrint("$yellowLog [ResponseApi]: InteractionID: $interactionID");
    debugPrint("$yellowLog [ResponseApi]: QuestionID: $questionID");
    debugPrint("$yellowLog [ResponseApi]: AnswerID: $answerID");
    debugPrint("$yellowLog [ResponseApi]: Text: ${payload["text"]}");
    debugPrint("$yellowLog [ResponseApi]: Text length: ${payload["text"]?.toString().length ?? 0}");
    debugPrint("$yellowLog========================================");

    http.Response response = await client.post(
      'response/',
      payload,
      authenticated: true,
    );

    debugPrint("$yellowLog========================================");
    debugPrint("$yellowLog [ResponseApi]: BACKEND RESPONSE RECEIVED");
    debugPrint("$yellowLog [ResponseApi]: Status: ${response.statusCode}");
    debugPrint("$yellowLog [ResponseApi]: Body: ${response.body}");
    debugPrint("$yellowLog========================================");

    if (response.statusCode == HttpStatus.ok ||
        response.statusCode == HttpStatus.created) {
      debugPrint(
        "$greenLog✓ [ResponseApi]: Response successfully submitted to backend!",
      );
      
      // Check for conveyance in response body
      Conveyance? conveyance;
      try {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        if (responseBody.containsKey('conveyance') && responseBody['conveyance'] != null) {
          debugPrint("$yellowLog [ResponseApi]: 🔔 Conveyance detected in response!");
          conveyance = Conveyance.fromJson(responseBody['conveyance']);
          debugPrint("$yellowLog [ResponseApi]: Conveyance message: ${conveyance.messageText}");
        }
      } catch (e) {
        debugPrint("$redLog [ResponseApi]: Error parsing conveyance: $e");
      }
      
      return ResponseSubmissionResult(success: true, conveyance: conveyance);
    } else {
      debugPrint("$redLog✗ [ResponseApi]: FAILED to submit response!");
      debugPrint("$redLog [ResponseApi]: Status code: ${response.statusCode}");
      debugPrint("$redLog [ResponseApi]: Response body: ${response.body}");
      return ResponseSubmissionResult(success: false);
    }
  }

  @override
  Future<List<dynamic>> getMyResponsesRaw() async {
    final yellowLog = '\x1B[93m';
    final redLog = '\x1B[31m';
    final greenLog = '\x1B[32m';

    try {
      debugPrint("$yellowLog[ResponseApi]: GET /responses/me/");
      final http.Response response = await client.get(
        'responses/me/',
        authenticated: true,
      );
      debugPrint("$yellowLog[ResponseApi]: Status: ${response.statusCode}");

      if (response.statusCode == HttpStatus.ok) {
        final body = response.body;
        final parsed = jsonDecode(body);
        if (parsed is List) {
          debugPrint("$greenLog[ResponseApi]: Received ${parsed.length} responses");
          return parsed;
        }
        debugPrint("$redLog[ResponseApi]: Unexpected body format for responses/me");
        return [];
      }
      debugPrint("$redLog[ResponseApi]: Failed (${response.statusCode}) body: ${response.body}");
      return [];
    } catch (e) {
      debugPrint("$redLog[ResponseApi]: Error fetching my responses: $e");
      return [];
    }
  }
}
