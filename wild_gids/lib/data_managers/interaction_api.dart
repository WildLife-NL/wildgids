import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:wildgids/data_managers/api_client.dart';
import 'package:wildgids/interfaces/data_apis/interaction_api_interface.dart';
import 'package:wildgids/models/api_models/questionaire.dart';
import 'package:wildgids/models/beta_models/animal_sighting_report_wrapper.dart';
import 'package:wildgids/models/beta_models/interaction_model.dart';
import 'package:wildgids/models/beta_models/interaction_response_model.dart';
import 'package:wildgids/models/enums/interaction_type.dart';

class InteractionApi implements InteractionApiInterface {
  final ApiClient client;
  final greenLog = '\x1B[32m';
  final redLog = '\x1B[31m';
  final yellowLog = '\x1B[93m';
  InteractionApi(this.client);

  @override
  Future<InteractionResponse> sendInteraction(Interaction interaction) async {
    try {
      debugPrint("$yellowLog[InteractionAPI]: Starting sendInteraction");
      http.Response response;

      switch (interaction.interactionType) {
        case InteractionType.waarneming:
          debugPrint("$yellowLog[InteractionAPI]: Report is waarneming");
          if (interaction.report is AnimalSightingReportWrapper) {
            final apiPayload =
                interaction.report
                    .toJson(); // Use the wrapper's toJson directly
            response = await client.post(
              'interaction/',
              apiPayload,
              authenticated: true,
            );
          } else {
            throw Exception(
              "Invalid report type for waarnemning: ${interaction.report.runtimeType}",
            );
          }
          break;
      }

      debugPrint(
        "$greenLog[InteractionAPI] Response code: ${response.statusCode}",
      );
      debugPrint("$greenLog[InteractionAPI] Response body: ${response.body}");

      if (response.statusCode == HttpStatus.ok) {
        final json = jsonDecode(response.body);
        if (json == null) {
          throw Exception("Empty response received from server");
        }

        debugPrint("$yellowLog========================================");
        debugPrint("$yellowLog[InteractionAPI]: CHECKING FOR QUESTIONNAIRE");
        final questionnaireJson = json['questionnaire'];
        final String interactionID = json['ID'];

        debugPrint(
          "$yellowLog[InteractionAPI]: InteractionID from backend: $interactionID",
        );
        debugPrint(
          "$yellowLog[InteractionAPI]: Questionnaire in response: ${questionnaireJson != null ? 'YES' : 'NO'}",
        );

        if (questionnaireJson != null) {
          debugPrint("$yellowLog[InteractionAPI]: Questionnaire data:");
          debugPrint("$yellowLog${jsonEncode(questionnaireJson)}");
          
          // Detailed breakdown of questions and answers
          debugPrint("$yellowLogâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•");
          debugPrint("$yellowLog[InteractionAPI]: DETAILED QUESTION ANALYSIS");
          debugPrint("$yellowLogâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•");
          final questionsArray = questionnaireJson['questions'];
          if (questionsArray != null && questionsArray is List) {
            debugPrint("$yellowLogðŸ“‹ Total questions: ${questionsArray.length}");
            for (int i = 0; i < questionsArray.length; i++) {
              final q = questionsArray[i];
              debugPrint("$yellowLogâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€");
              debugPrint("$yellowLog[Q${i + 1}] ${q['text']}");
              debugPrint("$yellowLog    ID: ${q['ID']}");
              debugPrint("$yellowLog    allowMultipleResponse: ${q['allowMultipleResponse']}");
              debugPrint("$yellowLog    allowOpenResponse: ${q['allowOpenResponse']}");
              
              final answers = q['answers'];
              if (answers != null && answers is List) {
                debugPrint("$yellowLog    âœ… Has ${answers.length} answers:");
                for (int j = 0; j < answers.length; j++) {
                  final a = answers[j];
                  debugPrint("$yellowLog       [A${j + 1}] ${a['text']} (ID: ${a['ID']})");
                }
              } else {
                debugPrint("$yellowLog    âŒ NO ANSWERS PROVIDED by backend!");
              }
            }
          }
          debugPrint("$yellowLogâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•");
        }
        debugPrint("$yellowLog========================================");

        if (questionnaireJson == null) {
          // Graceful handling: not all interactions yield questionnaires.
          debugPrint(
            "$yellowLog[InteractionAPI]: â–¶ No questionnaire returned. Proceeding without questionnaire.",
          );
          return InteractionResponse.empty(interactionID: interactionID);
        }

        try {
          return InteractionResponse(
            questionnaire: Questionnaire.fromJson(questionnaireJson),
            interactionID: interactionID,
          );
        } catch (e) {
          debugPrint("$redLog Error parsing questionnaire: $e");
          // Fallback: return an empty questionnaire response instead of failing whole interaction
          return InteractionResponse.empty(interactionID: interactionID);
        }
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessages =
            (errorBody['errors'] as List?)
                ?.map((e) => e['message'])
                .join('; ') ??
            errorBody['detail'] ??
            'Unknown error';
        throw Exception(
          "API request failed with status ${response.statusCode}: $errorMessages",
        );
      }
    } catch (e) {
      debugPrint("$redLog[InteractionAPI] Error: $e");
      throw Exception("Failed to send interaction: $e");
    }
  }

  // Removed fallback questionnaire fetch by hardcoded ID; questionnaires must come from backend response
}

