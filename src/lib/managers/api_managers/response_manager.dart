import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:wildgids/interfaces/reporting/response_interface.dart';
import 'package:wildgids/interfaces/data_apis/response_api_interface.dart';
import 'package:wildgids/models/beta_models/response_model.dart';
import 'package:wildgids/providers/response_provider.dart';
import 'package:wildgids/utils/connection_checker.dart';
import 'package:wildgids/utils/notification_service.dart';

class ResponseManager implements ResponseInterface {
  ResponseApiInterface responseAPI;
  final ResponseProvider responseProvider;

  final Connectivity _connectivity;
  late final StreamSubscription<List<ConnectivityResult>>
  _connectivitySubscription;

  bool _isRetryingSend = false;

  final greenLog = '\x1B[32m';
  final redLog = '\x1B[31m';
  final yellowLog = '\x1B[93m';

  ResponseManager({
    required this.responseAPI,
    required this.responseProvider,
    Connectivity? connectivity,
  }) : _connectivity = connectivity ?? Connectivity();

  void init() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _handleConnectivityChange,
    );
  }

  void dispose() {
    _connectivitySubscription.cancel();
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) async {
    debugPrint(results.toString());

    final hasConnection = results.any((r) => r != ConnectivityResult.none);

    if (hasConnection) {
      await _trySendCachedData();
    } else {
      debugPrint('No internet connection â€“ future data will be cached.');
    }
  }

  void _scheduleRetryUntilSuccess() {
    if (_isRetryingSend) return;
    _isRetryingSend = true;

    _retryLoop();
  }

  void _retryLoop() async {
    while (true) {
      bool hasConnection = await ConnectionChecker.hasInternetConnection();
      if (hasConnection) {
        try {
          await _trySendCachedData();
          debugPrint("$greenLog Successfully sent cached data.");
          _isRetryingSend = false;
          break; // Stop retrying after success
        } catch (e) {
          debugPrint("$yellowLog Retry failed. Will try again in 10 seconds.");
        }
      } else {
        debugPrint("$yellowLog No internet. Will check again in 10 seconds.");
      }
      await Future.delayed(Duration(seconds: 10));
    }
  }

  Future<void> _trySendCachedData() async {
    if (!await ConnectionChecker.hasInternetConnection()) {
      debugPrint("$yellowLog Internet not fully ready. Retry later.");
      _scheduleRetryUntilSuccess();
      return;
    }
    submitResponses();
  }

  @override
  Future<void> storeResponse(
    Response response,
    String questionaireID,
    String questionID,
  ) async {
    try {
      debugPrint("$yellowLog [ResponseManager]: === Storing Response ===");
      debugPrint(
        "$yellowLog [ResponseManager]: Questionnaire: $questionaireID",
      );
      debugPrint("$yellowLog [ResponseManager]: Question: $questionID");
      debugPrint(
        "$yellowLog [ResponseManager]: Answer ID: ${response.answerID}",
      );
      debugPrint("$yellowLog [ResponseManager]: Text: ${response.text}");

      SharedPreferences prefs = await SharedPreferences.getInstance();

      List<ResponsesListObject>? storedResponsesList =
          await _getAlreadyStoredresponseListObjects();

      List<ResponsesListObject> responses = storedResponsesList ?? [];

      ResponsesListObject responsesListObject;
      if (responses.isEmpty) {
        responsesListObject = ResponsesListObject(responses: []);
        responses.add(responsesListObject);
      } else {
        responsesListObject = responses[0];
      }

      List<ResponseObject> responseObjects = [];

      // Check for multiple answerIDs (e.g., comma-separated)
      if (response.answerID != null && response.answerID!.contains(',')) {
        // Multiple answers - split by comma
        List<String> answerIDs = response.answerID!.split(',');
        debugPrint(
          "$yellowLog [ResponseManager]: Splitting multiple answers: ${answerIDs.length} answers",
        );
        for (String id in answerIDs) {
          responseObjects.add(
            ResponseObject(
              questionID: questionID,
              response: Response(
                interactionID: response.interactionID,
                questionID: response.questionID,
                answerID: id.trim(),
                text: response.text,
              ),
            ),
          );
        }
      } else {
        // Single answer or open-ended text response
        debugPrint(
          "$yellowLog [ResponseManager]: Storing single response - Question: $questionID, Answer: ${response.answerID}, Text: ${response.text}",
        );
        responseObjects.add(
          ResponseObject(questionID: questionID, response: response),
        );
      }

      bool found = false;

      // Try to find existing entry
      for (var entry in responsesListObject.responses) {
        if (entry.containsKey(questionaireID)) {
          debugPrint(
            "$yellowLog [ResponseManager]: Found existing questionnaire entry, adding ${responseObjects.length} response(s)",
          );
          entry[questionaireID]!.addAll(responseObjects);
          found = true;
          break;
        }
      }

      if (!found) {
        debugPrint(
          "$yellowLog [ResponseManager]: Creating new questionnaire entry with ${responseObjects.length} response(s)",
        );
        responsesListObject.responses.add({questionaireID: responseObjects});
      }

      List<String> jsonStringList =
          responses.map((obj) => jsonEncode(obj.toJson())).toList();
      await prefs.setStringList('responses', jsonStringList);

      debugPrint("$greenLog [ResponseManager]: Response stored successfully!");
      debugPrint(
        "$yellowLog [ResponseManager]: Total responses in storage: ${responsesListObject.responses.length} questionnaire(s)",
      );

      responseProvider.clearResponse();
    } catch (e, stackTrace) {
      debugPrint(e.toString());
      debugPrint(stackTrace.toString());
      rethrow;
    }
  }

  @override
  Future<void> updateResponse(
    Response updatedResponses,
    String questionaireID,
    String questionID,
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<ResponsesListObject>? storedResponsesList =
        await _getAlreadyStoredresponseListObjects();

    // If no existing data, initialize empty list
    List<ResponsesListObject> responses = storedResponsesList ?? [];

    // There should only be one ReponseListObject in practice
    ResponsesListObject responsesListObject;
    if (responses.isEmpty) {
      responsesListObject = ResponsesListObject(responses: []);
      responses.add(responsesListObject);
    } else {
      responsesListObject = responses[0];
    }

    bool questionnaireFound = false;
    bool responseUpdated = false;

    for (var entry in responsesListObject.responses) {
      if (entry.containsKey(questionaireID)) {
        questionnaireFound = true;
        List<ResponseObject> responsesList = entry[questionaireID]!;

        for (int i = 0; i < responsesList.length; i++) {
          if (responsesList[i].questionID == questionID) {
            // Update the response
            responsesList[i] = ResponseObject(
              questionID: questionID,
              response: updatedResponses,
            );
            responseUpdated = true;
            break;
          }
        }

        // If questionID not found, add a new ResponseObject
        if (!responseUpdated) {
          responsesList.add(
            ResponseObject(questionID: questionID, response: updatedResponses),
          );
        }

        break;
      }
    }

    // If questionaireID not found at all, create new entry
    if (!questionnaireFound) {
      responsesListObject.responses.add({
        questionaireID: [
          ResponseObject(questionID: questionID, response: updatedResponses),
        ],
      });
    }

    // Save the updated structure back to SharedPreferences
    List<String> jsonStringList =
        responses.map((obj) => jsonEncode(obj.toJson())).toList();
    await prefs.setStringList('responses', jsonStringList);
  }

  Future<List<ResponsesListObject>?>
  _getAlreadyStoredresponseListObjects() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? jsonStringList = prefs.getStringList('responses');
    debugPrint("$yellowLog [ResponseManager]: jsonStringList = ");
    debugPrint("$yellowLog $jsonStringList");

    if (jsonStringList != null) {
      List<ResponsesListObject> responses =
          jsonStringList
              .map(
                (jsonString) =>
                    ResponsesListObject.fromJson(jsonDecode(jsonString)),
              )
              .toList();

      // Check if all ResponsesListObject instances contain no meaningful data
      bool allEmpty = responses.every(
        (r) =>
            r.responses.isEmpty ||
            (r.responses.length == 1 && r.responses.first.isEmpty),
      );

      if (allEmpty) {
        debugPrint("$yellowLog All responses are empty. Returning null.");
        return null;
      }
      return responses;
    }
    return null;
  }

  @override
  Future<void> submitResponses() async {
    debugPrint(
      "$yellowLog [ResponseManager]: === Starting submitResponses ===",
    );
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<ResponsesListObject>? storedResponsesList =
        await _getAlreadyStoredresponseListObjects();

    if (storedResponsesList == null || storedResponsesList.isEmpty) {
      debugPrint("$redLog [ResponseManager]: No stored responses to submit.");
      return;
    }

    List<ResponsesListObject> responsesList = storedResponsesList;
    debugPrint(
      "$yellowLog [ResponseManager]: Found ${responsesList.length} response list objects",
    );

    final results = await _connectivity.checkConnectivity();
    debugPrint(results.toString());
    final hasConnection = results.any((r) => r != ConnectivityResult.none);

    if (hasConnection) {
      int totalResponses = 0;
      int successfulResponses = 0;

      for (int i = 0; i < responsesList.length; i++) {
        ResponsesListObject listObject = responsesList[i];
        debugPrint(
          "$yellowLog [ResponseManager]: Processing list object $i with ${listObject.responses.length} questionnaires",
        );

        // For each questionnaire entry
        for (int j = 0; j < listObject.responses.length; j++) {
          Map<String, List<ResponseObject>> entry = listObject.responses[j];
          String questionaireID = entry.keys.first;
          List<ResponseObject> responseObjects = entry[questionaireID]!;

          debugPrint(
            "$yellowLog [ResponseManager]: Questionnaire $questionaireID has ${responseObjects.length} responses to submit",
          );

          List<ResponseObject> failedResponses = [];

          for (var responseObj in responseObjects) {
            totalResponses++;
            Response r = responseObj.response;
            debugPrint(
              "$yellowLog [ResponseManager]: Submitting response $totalResponses - Question: ${r.questionID}",
            );

            final result = await responseAPI.addReponse(
              r.interactionID,
              r.questionID,
              r.answerID,
              r.text,
            );

            if (!result.success) {
              failedResponses.add(responseObj);
              debugPrint(
                "$redLog [ResponseManager]: Response $totalResponses FAILED",
              );
            } else {
              successfulResponses++;
              debugPrint(
                "$greenLog [ResponseManager]: Response $totalResponses SUCCESS",
              );
              
              // Check for conveyance and trigger notification
              if (result.conveyance != null) {
                final messageText = result.conveyance!.messageText;
                if (messageText != null && messageText.isNotEmpty) {
                  debugPrint(
                    "$yellowLog [ResponseManager]: ðŸ”” Triggering notification for conveyance: $messageText",
                  );
                  try {
                    await NotificationService.instance.showConveyanceNotification(
                      messageText: messageText,
                      animalName: result.conveyance!.animalName,
                    );
                  } catch (e) {
                    debugPrint(
                      "$redLog [ResponseManager]: Failed to show notification: $e",
                    );
                  }
                }
              }
            }
          }

          // Update the entry with only failed responses if there were any
          if (failedResponses.isNotEmpty) {
            listObject.responses[j][questionaireID] = failedResponses;
            debugPrint(
              "$yellowLog [ResponseManager]: ${failedResponses.length} responses failed, keeping in storage",
            );
          } else {
            // Remove successfully submitted questionnaire entry
            listObject.responses[j].remove(questionaireID);
            debugPrint(
              "$greenLog [ResponseManager]: All responses for questionnaire $questionaireID submitted successfully",
            );
          }
        }
      }

      debugPrint("$yellowLog [ResponseManager]: === Submit Summary ===");
      debugPrint(
        "$yellowLog [ResponseManager]: Total: $totalResponses, Successful: $successfulResponses, Failed: ${totalResponses - successfulResponses}",
      );

      // Remove empty entries and persist updated list
      responsesList.removeWhere((object) => object.responses.isEmpty);

      if (responsesList.isEmpty) {
        await prefs.remove('responses');
        debugPrint(
          "$greenLog [ResponseManager]: All stored responses submitted and cleared.",
        );
      } else {
        List<String> updatedJson =
            responsesList.map((obj) => jsonEncode(obj.toJson())).toList();
        await prefs.setStringList('responses', updatedJson);
        debugPrint(
          "Some responses failed to submit; remaining ones kept in storage.",
        );
      }
      responseProvider.clearResponsesList();
      responseProvider.clearResponse();
    }
  }
}

class ResponsesListObject {
  final List<Map<String, List<ResponseObject>>> responses;

  ResponsesListObject({required this.responses});

  factory ResponsesListObject.fromJson(Map<String, dynamic> json) {
    return ResponsesListObject(
      responses:
          (json['responses'] as List).map((entry) {
            final mapEntry = entry as Map<String, dynamic>;
            return mapEntry.map((key, value) {
              return MapEntry(
                key,
                (value as List)
                    .map((item) => ResponseObject.fromJson(item))
                    .toList(),
              );
            });
          }).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'responses':
          responses.map((entry) {
            return entry.map((key, value) {
              return MapEntry(
                key,
                value.map((answerObj) => answerObj.toJson()).toList(),
              );
            });
          }).toList(),
    };
  }
}

class ResponseObject {
  final String questionID;
  final Response response;

  ResponseObject({required this.questionID, required this.response});

  factory ResponseObject.fromJson(Map<String, dynamic> json) {
    return ResponseObject(
      questionID: json['questionID'],
      response: Response.fromJson(json['response']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'questionID': questionID, 'response': response.toJson()};
  }
}

