import 'package:wildgids/models/api_models/living_labs.dart';
import 'package:wildgids/models/api_models/user.dart';

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

    final rawUser = json['user'];
    final user = rawUser is Map<String, dynamic>
        ? User.fromJson(rawUser)
        : rawUser is Map
            ? User.fromJson(Map<String, dynamic>.from(rawUser))
            : User(id: 'N/A', email: null);

    return Experiment(
      id: json['ID']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      end: contertedEnd,
      livingLab: convertedLivingLabs,
      messageActivity: json['messageActivity'],
      name: json['name']?.toString() ?? '',
      numberOfMessages: json['numberOfMessages'],
      numberOfQuestionnaires: json['numberOfQuestionnaires'],
      questionnaireActivity: json['questionnaireActivity'],
      start: DateTime.parse(json['start'].toString()),
      user: user,
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

