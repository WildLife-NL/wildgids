import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:wildrapport/data_managers/api_client.dart';
import 'package:wildrapport/interfaces/data_apis/interaction_api_interface.dart';
import 'package:wildrapport/interfaces/reporting/common_report_fields.dart';
import 'package:wildrapport/interfaces/reporting/possesion_report_fields.dart';
import 'package:wildrapport/models/api_models/questionaire.dart';
import 'package:wildrapport/models/beta_models/animal_sighting_report_wrapper.dart';
import 'package:wildrapport/models/beta_models/interaction_model.dart';
import 'package:wildrapport/models/beta_models/interaction_response_model.dart';
import 'package:wildrapport/models/enums/interaction_type.dart';

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
        case InteractionType.gewasschade:
          debugPrint("$yellowLog========================================");
          debugPrint("$yellowLog[InteractionAPI]: Report is gewasschade");
          if (interaction.report is PossesionReportFields) {
            final report = interaction.report as PossesionReportFields;
            final payload = {
              "description": report.description ?? '',
              "location": {
                "latitude": report.systemLocation?.latitude,
                "longitude": report.systemLocation?.longtitude,
              },
              "moment": report.userSelectedDateTime?.toUtc().toIso8601String(),
              "place": {
                "latitude": report.userSelectedLocation?.latitude,
                "longitude": report.userSelectedLocation?.longtitude,
              },
              "reportOfDamage": {
                "belonging": report.possesion.toJson(),
                "estimatedDamage": report.currentImpactDamages.toInt(),
                "estimatedLoss": report.estimatedTotalDamages.toInt(),
                "impactType": report.impactedAreaType,
                "impactValue": report.impactedArea.toInt(),
              },
              "speciesID": report.suspectedSpeciesID,
              "typeID": 2,
            };
            debugPrint("$yellowLog[InteractionAPI]: GEWASSCHADE Payload:");
            debugPrint("$yellowLog${jsonEncode(payload)}");
            debugPrint("$yellowLog========================================");
            response = await client.post('interaction/', payload, authenticated: true);
          } else {
            throw Exception(
              "Invalid report type for gewasschade: ${interaction.report.runtimeType}",
            );
          }
          break;
        case InteractionType.verkeersongeval:
          debugPrint("$yellowLog[InteractionAPI]: Report is verkeersongeval");
          if (interaction.report is CommonReportFields) {
            final report = interaction.report as CommonReportFields;
            response = await client.post('interaction/', {
              "description": report.description ?? '',
              "location": {
                "latitude": report.systemLocation?.latitude,
                "longitude": report.systemLocation?.longtitude,
              },
              "moment": report.userSelectedDateTime?.toUtc().toIso8601String(),
              "place": {
                "latitude": report.userSelectedLocation?.latitude,
                "longitude": report.userSelectedLocation?.longtitude,
              },
              "reportOfCollision": interaction.report.toJson(),
              "speciesID": report.suspectedSpeciesID,
              "typeID": 3,
            }, authenticated: true);
          } else {
            throw Exception(
              "Invalid report type for verkeersongeval: ${interaction.report.runtimeType}",
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
        
        debugPrint("$yellowLog[InteractionAPI]: InteractionID from backend: $interactionID");
        debugPrint("$yellowLog[InteractionAPI]: Questionnaire in response: ${questionnaireJson != null ? 'YES' : 'NO'}");
        
        if (questionnaireJson != null) {
          debugPrint("$yellowLog[InteractionAPI]: Questionnaire data:");
          debugPrint("$yellowLog${jsonEncode(questionnaireJson)}");
        }
        debugPrint("$yellowLog========================================");
        
        if (questionnaireJson == null) {
          debugPrint("$redLog[InteractionAPI]: ✗ No questionnaire data in response");
          debugPrint("$redLog[InteractionAPI]: This means the backend did not return a questionnaire for this interaction type");
          throw Exception("No questionnaire provided by backend");
        }

        try {
          return InteractionResponse(
            questionnaire: Questionnaire.fromJson(questionnaireJson),
            interactionID: interactionID,
          );
        } catch (e) {
          debugPrint("$redLog Error parsing questionnaire: $e");
          throw Exception("Invalid questionnaire format: $e");
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
