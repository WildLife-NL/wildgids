import 'package:wildrapport/models/api_models/answer.dart';

class Question {
  String id;
  bool allowMultipleResponse;
  bool allowOpenResponse;
  List<Answer>? answers;
  String description;
  int index;
  String? openResponseFormat;
  String text;

  Question({
    required this.id,
    required this.allowMultipleResponse,
    required this.allowOpenResponse,
    required this.answers,
    required this.description,
    required this.index,
    required this.text,
    this.openResponseFormat,
  });

  factory Question.fromJson(Map<String, dynamic> json) => Question(
    id: json["ID"],
    allowMultipleResponse: json["allowMultipleResponse"],
    allowOpenResponse: json["allowOpenResponse"],
    answers:
        json["answers"] != null
            ? List<Answer>.from(json["answers"].map((x) => Answer.fromJson(x)))
            : null,
    description: json["description"],
    index: json["index"],
    openResponseFormat: json["openResponseFormat"],
    text: json["text"],
  );

  Map<String, dynamic> toJson() {
    return {
      "ID": id,
      "allowMultipleResponse": allowMultipleResponse,
      "allowOpenResponse": allowOpenResponse,
      "answers":
          answers != null
              ? List<dynamic>.from(answers!.map((x) => x.toJson()))
              : null,
      "description": description,
      "index": index,
      "openResponseFormat": openResponseFormat,
      "text": text,
    };
  }
}
