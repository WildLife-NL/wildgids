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
    
    debugPrint("$yellowLog========================================");
    debugPrint("$yellowLog [ResponseApi]: SENDING RESPONSE TO BACKEND");
    debugPrint("$yellowLog [ResponseApi]: Endpoint: POST /response/");
    debugPrint("$yellowLog [ResponseApi]: InteractionID: $interactionID");
    debugPrint("$yellowLog [ResponseApi]: QuestionID: $questionID");
    debugPrint("$yellowLog [ResponseApi]: AnswerID: $answerID");
    debugPrint("$yellowLog [ResponseApi]: Text: $text");
    debugPrint("$yellowLog [ResponseApi]: Full Payload: $payload");
    debugPrint("$yellowLog========================================");
    
    http.Response response = await client.post('response/', payload, authenticated: true);

    debugPrint("$yellowLog========================================");
    debugPrint("$yellowLog [ResponseApi]: BACKEND RESPONSE RECEIVED");
    debugPrint("$yellowLog [ResponseApi]: Status: ${response.statusCode}");
    debugPrint("$yellowLog [ResponseApi]: Body: ${response.body}");
    debugPrint("$yellowLog========================================");
    
    if (response.statusCode == HttpStatus.ok || response.statusCode == HttpStatus.created) {
      debugPrint("$greenLog✓ [ResponseApi]: Response successfully submitted to backend!");
      return true;
    } else {
      debugPrint("$redLog✗ [ResponseApi]: FAILED to submit response!");
      debugPrint("$redLog [ResponseApi]: Status code: ${response.statusCode}");
      debugPrint("$redLog [ResponseApi]: Response body: ${response.body}");
      return false;
    }
  }
}
