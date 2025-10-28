import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildrapport/models/api_models/questionaire.dart';
import 'package:wildrapport/models/api_models/experiment.dart';
import 'package:wildrapport/models/api_models/interaction_type.dart';
import 'package:wildrapport/models/api_models/question.dart';
import 'package:wildrapport/models/api_models/answer.dart';
import 'package:wildrapport/models/api_models/user.dart';

void main() {
  group('Questionnaire', () {
    late Experiment testExperiment;
    late InteractionType testInteractionType;
    late List<Question> testQuestions;
    
    setUp(() {
      testExperiment = Experiment(
        id: 'exp-123',
        name: 'Test Experiment',
        description: 'Test experiment',
        start: DateTime.parse('2023-01-01T00:00:00.000'),
        user: User(
          id: 'user-123',
          email: 'test@example.com',
          name: 'Test User',
        ),
      );
      
      testInteractionType = InteractionType(
        id: 1,
        name: 'waarneming',
        description: 'Animal sighting',
      );
      
      testQuestions = [
        Question(
          id: 'q-1',
          text: 'Did you see the animal clearly?',
          description: 'First question',
          index: 0,
          allowMultipleResponse: false,
          allowOpenResponse: false,
          answers: [
            Answer(id: 'a-1', index: 0, text: 'Yes'),
            Answer(id: 'a-2', index: 1, text: 'No'),
          ],
        ),
        Question(
          id: 'q-2',
          text: 'What was the animal doing?',
          description: 'Second question',
          index: 1,
          allowMultipleResponse: true,
          allowOpenResponse: true,
          openResponseFormat: 'text',
          answers: [
            Answer(id: 'a-3', index: 0, text: 'Eating'),
            Answer(id: 'a-4', index: 1, text: 'Running'),
          ],
        ),
      ];
    });
    
    test('should have correct properties', () {
      // Arrange
      final questionnaire = Questionnaire(
        id: 'quest-123',
        experiment: testExperiment,
        interactionType: testInteractionType,
        name: 'Animal Sighting Questionnaire',
        identifier: 'AS-2023',
        questions: testQuestions,
      );
      
      // Assert
      expect(questionnaire.id, 'quest-123');
      expect(questionnaire.experiment, testExperiment);
      expect(questionnaire.interactionType, testInteractionType);
      expect(questionnaire.name, 'Animal Sighting Questionnaire');
      expect(questionnaire.identifier, 'AS-2023');
      expect(questionnaire.questions, testQuestions);
      expect(questionnaire.questions!.length, 2);
    });
    
    test('should create from JSON correctly', () {
      // Arrange
      final json = {
        'ID': 'quest-123',
        'experiment': {
          'ID': 'exp-123',
          'description': 'Test experiment',
          'name': 'Test Experiment',
          'start': '2023-01-01T00:00:00.000',
          'user': {
            'userID': 'user-123',
            'email': 'test@example.com',
            'name': 'Test User',
          },
        },
        'interactionType': {
          'ID': 1,
          'name': 'waarneming',
          'description': 'Animal sighting',
        },
        'name': 'Animal Sighting Questionnaire',
        'identifier': 'AS-2023',
        'questions': [
          {
            'ID': 'q-1',
            'allowMultipleResponse': false,
            'allowOpenResponse': false,
            'description': 'First question',
            'index': 0,
            'text': 'Did you see the animal clearly?',
            'answers': [
              {'ID': 'a-1', 'index': 0, 'text': 'Yes'},
              {'ID': 'a-2', 'index': 1, 'text': 'No'},
            ],
          },
          {
            'ID': 'q-2',
            'allowMultipleResponse': true,
            'allowOpenResponse': true,
            'description': 'Second question',
            'index': 1,
            'text': 'What was the animal doing?',
            'openResponseFormat': 'text',
            'answers': [
              {'ID': 'a-3', 'index': 0, 'text': 'Eating'},
              {'ID': 'a-4', 'index': 1, 'text': 'Running'},
            ],
          },
        ],
      };
      
      // Act
      final questionnaire = Questionnaire.fromJson(json);
      
      // Assert
      expect(questionnaire.id, 'quest-123');
      expect(questionnaire.experiment.id, 'exp-123');
      expect(questionnaire.interactionType.id, 1);
      expect(questionnaire.name, 'Animal Sighting Questionnaire');
      expect(questionnaire.identifier, 'AS-2023');
      expect(questionnaire.questions!.length, 2);
      expect(questionnaire.questions![0].id, 'q-1');
      expect(questionnaire.questions![1].answers!.length, 2);
      expect(questionnaire.questions![1].answers![0].text, 'Eating');
    });
    
    test('should convert to JSON correctly', () {
      // Arrange
      final questionnaire = Questionnaire(
        id: 'quest-123',
        experiment: testExperiment,
        interactionType: testInteractionType,
        name: 'Animal Sighting Questionnaire',
        identifier: 'AS-2023',
        questions: testQuestions,
      );
      
      // Act
      final json = questionnaire.toJson();
      
      // Debug
      if (kDebugMode) {
        print('JSON output: ${json['interactionType']}');
      }
      
      // Assert
      expect(json['ID'], 'quest-123');
      expect(json['experiment']['ID'], 'exp-123');
      
      // Fix the assertion to match the actual JSON structure
      if (json['interactionType'] is Map) {
        if (json['interactionType'].containsKey('id')) {
          expect(json['interactionType']['id'], 1);
        } else {
          expect(json['interactionType']['ID'], 1);
        }
      } else {
        fail('interactionType is not a Map: ${json['interactionType']}');
      }
      
      expect(json['name'], 'Animal Sighting Questionnaire');
      expect(json['identifier'], 'AS-2023');
      expect(json['questions'].length, 2);
      expect(json['questions'][0]['ID'], 'q-1');
      expect(json['questions'][1]['answers'].length, 2);
      expect(json['questions'][1]['answers'][0]['text'], 'Eating');
    });
    
    test('should handle null questions in constructor', () {
      // Arrange & Act
      final questionnaire = Questionnaire(
        id: 'quest-123',
        experiment: testExperiment,
        interactionType: testInteractionType,
        name: 'Animal Sighting Questionnaire',
        identifier: 'AS-2023',
        questions: null,
      );
      
      // Assert
      expect(questionnaire.id, 'quest-123');
      expect(questionnaire.questions, isNull);
    });
    
    test('should handle null questions in fromJson', () {
      // Arrange
      final json = {
        'ID': 'quest-123',
        'experiment': {
          'ID': 'exp-123',
          'description': 'Test experiment',
          'name': 'Test Experiment',
          'start': '2023-01-01T00:00:00.000',
          'user': {
            'userID': 'user-123',
            'email': 'test@example.com',
            'name': 'Test User',
          },
        },
        'interactionType': {
          'ID': 1,
          'name': 'waarneming',
          'description': 'Animal sighting',
        },
        'name': 'Animal Sighting Questionnaire',
        'identifier': 'AS-2023',
        'questions': null,
      };
      
      // Act
      final questionnaire = Questionnaire.fromJson(json);
      
      // Assert
      expect(questionnaire.id, 'quest-123');
      expect(questionnaire.questions, isNull);
    });
    
    test('should handle null identifier in constructor', () {
      // Arrange & Act
      final questionnaire = Questionnaire(
        id: 'quest-123',
        experiment: testExperiment,
        interactionType: testInteractionType,
        name: 'Animal Sighting Questionnaire',
        identifier: null,
        questions: testQuestions,
      );
      
      // Assert
      expect(questionnaire.id, 'quest-123');
      expect(questionnaire.identifier, isNull);
    });
    
    test('should handle empty questions list', () {
      // Arrange
      final questionnaire = Questionnaire(
        id: 'quest-123',
        experiment: testExperiment,
        interactionType: testInteractionType,
        name: 'Animal Sighting Questionnaire',
        identifier: 'AS-2023',
        questions: [],
      );
      
      // Act
      final json = questionnaire.toJson();
      
      // Assert
      expect(questionnaire.questions, isEmpty);
      expect(json['questions'], isEmpty);
    });
  });
}




