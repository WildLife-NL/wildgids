import 'package:wildrapport/models/api_models/questionaire.dart';

class InteractionResponse {
  Questionnaire questionnaire;
  String interactionID;
  InteractionResponse({
    required this.questionnaire,
    required this.interactionID,
  });
  factory InteractionResponse.fromJson(Map<String, dynamic> json) =>
      InteractionResponse(
        questionnaire: Questionnaire.fromJson(json["questionnaire"]),
        interactionID: json["interactionID"],
      );

  Map<String, dynamic> toJson() => {
    "questionnaire": questionnaire.toJson(),
    "interactionID": interactionID,
  };
}
