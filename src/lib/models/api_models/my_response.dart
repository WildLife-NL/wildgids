import 'package:flutter/foundation.dart';

class MyResponse {
  final String id;
  final String? freeText;
  final DateTime timestamp;
  final ResponseAnswer? answer;
  final ResponseQuestion? question;
  final ResponseInteraction? interaction;
  final Conveyance? conveyance;

  MyResponse({
    required this.id,
    required this.timestamp,
    this.freeText,
    this.answer,
    this.question,
    this.interaction,
    this.conveyance,
  });

  factory MyResponse.fromJson(Map<String, dynamic> json) {
    try {
      return MyResponse(
        id: json['ID']?.toString() ?? '',
        freeText: json['text']?.toString(),
        timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
        answer: json['answer'] != null ? ResponseAnswer.fromJson(json['answer']) : null,
        question: json['question'] != null ? ResponseQuestion.fromJson(json['question']) : null,
        interaction: json['interaction'] != null ? ResponseInteraction.fromJson(json['interaction']) : null,
        conveyance: json['conveyance'] != null ? Conveyance.fromJson(json['conveyance']) : null,
      );
    } catch (e) {
      if (kDebugMode) {
        print('[MyResponse] Failed parsing: $e');
      }
      rethrow;
    }
  }
}

class Conveyance {
  final String id;
  final DateTime timestamp;
  final String? messageText;
  final String? animalName;

  Conveyance({
    required this.id,
    required this.timestamp,
    this.messageText,
    this.animalName,
  });

  factory Conveyance.fromJson(Map<String, dynamic> json) {
    String? msgText;
    final msg = json['message'];
    if (msg is Map<String, dynamic>) {
      msgText = msg['text']?.toString();
      msgText ??= msg['message']?.toString();
    } else if (msg != null) {
      msgText = msg.toString();
    }

    String? name;
    final animal = json['animal'];
    if (animal is Map<String, dynamic>) {
      name = animal['name']?.toString();
      if ((name == null || name.isEmpty) && animal['species'] is Map<String, dynamic>) {
        final species = animal['species'] as Map<String, dynamic>;
        name = (species['commonName'] ?? species['name'])?.toString();
      }
    }

    return Conveyance(
      id: json['ID']?.toString() ?? '',
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      messageText: msgText,
      animalName: name,
    );
  }
}

class ResponseAnswer {
  final String id;
  final int? index;
  final String text;
  final String? nextQuestionID;

  ResponseAnswer({
    required this.id,
    required this.text,
    this.index,
    this.nextQuestionID,
  });

  factory ResponseAnswer.fromJson(Map<String, dynamic> json) => ResponseAnswer(
    id: json['ID']?.toString() ?? '',
    text: json['text']?.toString() ?? '',
    index: json['index'] is int ? json['index'] as int : int.tryParse(json['index']?.toString() ?? ''),
    nextQuestionID: json['nextQuestionID']?.toString(),
  );
}

class ResponseQuestion {
  final String id;
  final String? text;

  ResponseQuestion({required this.id, this.text});

  factory ResponseQuestion.fromJson(Map<String, dynamic> json) => ResponseQuestion(
    id: json['ID']?.toString() ?? '',
    text: json['text']?.toString(),
  );
}

class ResponseInteraction {
  final String id;
  final DateTime? moment;
  final ResponseQuestionnaire? questionnaire;

  ResponseInteraction({required this.id, this.moment, this.questionnaire});

  factory ResponseInteraction.fromJson(Map<String, dynamic> json) => ResponseInteraction(
    id: json['ID']?.toString() ?? '',
    moment: json['moment'] != null ? DateTime.tryParse(json['moment'].toString()) : null,
    questionnaire: json['questionnaire'] != null ? ResponseQuestionnaire.fromJson(json['questionnaire']) : null,
  );
}

class ResponseQuestionnaire {
  final String id;
  final String name;
  final String? identifier;
  final ResponseExperiment? experiment;

  ResponseQuestionnaire({
    required this.id,
    required this.name,
    this.identifier,
    this.experiment,
  });

  factory ResponseQuestionnaire.fromJson(Map<String, dynamic> json) => ResponseQuestionnaire(
    id: json['ID']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    identifier: json['identifier']?.toString(),
    experiment: json['experiment'] != null ? ResponseExperiment.fromJson(json['experiment']) : null,
  );
}

class ResponseExperiment {
  final String id;
  final String name;
  final String? description;

  ResponseExperiment({required this.id, required this.name, this.description});

  factory ResponseExperiment.fromJson(Map<String, dynamic> json) => ResponseExperiment(
    id: json['ID']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    description: json['description']?.toString(),
  );
}
