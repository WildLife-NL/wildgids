import 'package:wildrapport/models/api_models/living_labs.dart';
import 'package:wildrapport/models/api_models/user.dart';

class Experiment {
  String id;
  String description;
  DateTime? end;
  LivingLabs? livingLab;
  int? messageActivity;
  String name;
  int? numberOfMessages;
  int? numberOfQuestionnaires;
  int? questionnaireActivity;
  DateTime start;
  User user;

  Experiment({
    required this.id,
    required this.description,
    required this.name,
    required this.start,
    required this.user,
    this.livingLab,
    this.numberOfMessages,
    this.numberOfQuestionnaires,
    this.questionnaireActivity,
    this.messageActivity,
    this.end,
  });

  factory Experiment.fromJson(Map<String, dynamic> json) {
    DateTime? contertedEnd;
    LivingLabs? convertedLivingLabs;

    if (json["end"] != null) contertedEnd = DateTime.parse(json["end"]);
    if (json["livingLab"] != null) {
      convertedLivingLabs = LivingLabs.fromJson(json["livingLab"]);
    }

    return Experiment(
      id: json["ID"],
      description: json["description"],
      end: contertedEnd,
      livingLab: convertedLivingLabs,
      messageActivity: json["messageActivity"],
      name: json["name"],
      numberOfMessages: json["numberOfMessages"],
      numberOfQuestionnaires: json["numberOfQuestionnaires"],
      questionnaireActivity: json["questionnaireActivity"],
      start: DateTime.parse(json["start"]),
      user: User.fromJson(json["user"]),
    );
  }

  Map<String, dynamic> toJson() {
    String? endString;
    Map<String, dynamic>? livingLabString;

    if (end != null) {
      endString = end!.toIso8601String();
    }
    if (livingLab != null) {
      livingLabString = livingLab!.toJson();
    }

    return {
      "ID": id,
      "description": description,
      "end": endString,
      "livingLab": livingLabString,
      "messageActivity": messageActivity,
      "name": name,
      "numberOfMessages": numberOfMessages,
      "numberOfQuestionnaires": numberOfQuestionnaires,
      "questionnaireActivity": questionnaireActivity,
      "start": start.toIso8601String(),
      "user": user.toJson(),
    };
  }
}
