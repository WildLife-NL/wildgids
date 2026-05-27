import 'package:wildgids/models/api_models/experiment.dart';
import 'package:wildgids/models/api_models/interaction_type.dart';
import 'package:wildgids/models/api_models/question.dart';
import 'package:wildgids/models/api_models/user.dart';

class Questionnaire {
  String id;
  Experiment experiment;
  String? identifier;
  InteractionType interactionType;
  String name;
  List<Question>? questions;

  Questionnaire({
    required this.id,
    required this.experiment,
    required this.interactionType,
    required this.name,
    this.identifier,
    this.questions,
  });

  factory Questionnaire.fromJson(Map<String, dynamic> json) {
    final rawId = json['ID'] ?? json['id'];
    final rawExperiment = json['experiment'];
    final rawInteractionType = json['interactionType'];
    final rawName = json['name'];
    final rawQuestions = json['questions'] ?? json['Questions'];

    return Questionnaire(
      id: rawId?.toString() ?? 'N/A',
      experiment: rawExperiment != null
          ? Experiment.fromJson(
              rawExperiment is Map<String, dynamic>
                  ? rawExperiment
                  : Map<String, dynamic>.from(rawExperiment as Map),
            )
          : Experiment(
              id: 'N/A',
              description: '',
              name: 'N/A',
              start: DateTime.now(),
              user: User(id: 'N/A', email: null),
            ),
      identifier: json['identifier']?.toString(),
      interactionType: rawInteractionType != null
          ? InteractionType.fromJson(
              rawInteractionType is Map<String, dynamic>
                  ? rawInteractionType
                  : Map<String, dynamic>.from(rawInteractionType as Map),
            )
          : InteractionType(id: 0, name: 'N/A', description: ''),
      name: rawName?.toString() ?? 'Vragenlijst',
      questions: rawQuestions != null && rawQuestions is List
          ? List<Question>.from(
              rawQuestions.map(
                (x) => Question.fromJson(
                  x is Map<String, dynamic>
                      ? x
                      : Map<String, dynamic>.from(x as Map),
                ),
              ),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    List<dynamic>? listQuestions;

    if (questions != null) {
      listQuestions = List<dynamic>.from(questions!.map((x) => x.toJson()));
    }

    return {
      'ID': id,
      'experiment': experiment.toJson(),
      'identifier': identifier,
      'interactionType': interactionType.toJson(),
      'name': name,
      'questions': listQuestions,
    };
  }
}
