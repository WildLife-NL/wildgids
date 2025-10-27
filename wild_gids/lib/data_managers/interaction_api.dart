import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:widgets/data_managers/api_client.dart';
import 'package:widgets/models/beta_models/animal_sighting_report_wrapper.dart';
import 'package:widgets/models/enums/interaction_type.dart';

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
          debugPrint("$yellowLog[InteractionAPI]: Report is gewasschade");
          if (interaction.report is PossesionReportFields) {
            final report = interaction.report as PossesionReportFields;
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
              "reportOfDamage": {
                "belonging": report.possesion.toJson(),
                "estimatedDamage": report.currentImpactDamages.toInt(),
                "estimatedLoss": report.estimatedTotalDamages.toInt(),
                "impactType": report.impactedAreaType,
                "impactValue": report.impactedArea.toInt(),
              },
              "speciesID": report.suspectedSpeciesID,
              "typeID": 2,
            }, authenticated: true);
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

        final questionnaireJson = json['questionnaire'];
        debugPrint("$questionnaireJson");
        final String interactionID = json['ID'];
        if (questionnaireJson == null) {
          debugPrint("$redLog[InteractionAPI]: No questionnaire data in response");
          debugPrint("$yellowLog[InteractionAPI]: Using the fallback questionnaire!");
        }

        try {
          return InteractionResponse(
            questionnaire: questionnaireJson == null 
              ? await _getQuestionnaireByID("a634c0b2-e0ab-40e9-b3a4-6b28b177a482") 
              : Questionnaire.fromJson(questionnaireJson),
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
  //Temp, only here because of issues with the backend returning code 500 instead of expected response
  Future<Questionnaire> _getQuestionnaireByID(String id) async {
    http.Response response = await client.get(
      '/questionnaire/$id',
      authenticated: true,
    );

    Map<String, dynamic>? json;

    if (response.statusCode == HttpStatus.ok) {
      json = jsonDecode(response.body);
      Questionnaire questionnaire = Questionnaire.fromJson(json!);
      return questionnaire;
    } else {
      throw Exception(json ?? "Failed to get questionnaire");
    }
  }
}
