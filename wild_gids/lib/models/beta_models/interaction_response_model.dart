import 'package:wildgids/models/api_models/questionaire.dart';
import 'package:wildgids/models/api_models/experiment.dart';
import 'package:wildgids/models/api_models/interaction_type.dart' as api;
import 'package:wildgids/models/api_models/user.dart';

class InteractionResponse {
  Questionnaire questionnaire;
  String interactionID;
  InteractionResponse({
    required this.questionnaire,
    required this.interactionID,
  });

  // Factory to create an InteractionResponse without a questionnaire from backend
  // Uses a minimal placeholder Questionnaire with no questions
  factory InteractionResponse.empty({required String interactionID}) {
    final placeholder = Questionnaire(
      id: 'N/A',
      experiment: Experiment(
        id: 'N/A',
        description: 'No questionnaire provided by backend',
        name: 'No questionnaire',
        start: DateTime.now(),
        user: User(id: 'N/A', email: null),
      ),
      interactionType: api.InteractionType(
        id: 0,
        name: 'unknown',
        description: 'No questionnaire',
      ),
      name: 'No questionnaire',
      questions: const [],
    );
    return InteractionResponse(
      questionnaire: placeholder,
      interactionID: interactionID,
    );
  }
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

