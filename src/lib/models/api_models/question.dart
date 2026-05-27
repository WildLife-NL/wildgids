import 'package:wildgids/models/api_models/answer.dart';

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
        id: (json['ID'] ?? json['id'])?.toString() ?? '',
        allowMultipleResponse: json['allowMultipleResponse'] == true,
        allowOpenResponse: json['allowOpenResponse'] == true,
        answers: json['answers'] != null && json['answers'] is List
            ? List<Answer>.from(
                (json['answers'] as List).map(
                  (x) => Answer.fromJson(
                    x is Map<String, dynamic>
                        ? x
                        : Map<String, dynamic>.from(x as Map),
                  ),
                ),
              )
            : null,
        description: json['description']?.toString() ?? '',
        index: (json['index'] is int) ? json['index'] as int : 0,
        openResponseFormat: json['openResponseFormat']?.toString(),
        text: json['text']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'allowMultipleResponse': allowMultipleResponse,
      'allowOpenResponse': allowOpenResponse,
      'answers': answers != null
          ? List<dynamic>.from(answers!.map((x) => x.toJson()))
          : null,
      'description': description,
      'index': index,
      'openResponseFormat': openResponseFormat,
      'text': text,
    };
  }
}
