import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:wildgids/models/api_models/questionaire.dart';
import 'package:wildgids/models/api_models/experiment.dart';
import 'package:wildgids/models/api_models/interaction_type.dart';
import 'package:wildgids/models/api_models/question.dart';
import 'package:wildgids/models/api_models/user.dart';
import '../mock_generator.mocks.dart';

void main() {
  group('Questionnaire Model', () {
    late MockQuestionnaire mockQuestionnaire;
    late Experiment mockExperiment;
    late InteractionType mockInteractionType;

    setUp(() {
      mockQuestionnaire = MockQuestionnaire();
      mockExperiment = Experiment(
        id: 'exp1',
        name: 'Test Experiment',
        description: 'Test experiment description',
        start: DateTime.now(),
        user: User(id: 'user1', email: 'test@example.com', name: 'Test User'),
      );
      mockInteractionType = InteractionType(
        id: 1,
        name: 'Test Interaction',
        description: 'Test interaction description',
      );
    });

    test('should have correct properties', () {
      // Arrange
      final questionnaire = Questionnaire(
        id: '123',
        name: 'Test Questionnaire',
        experiment: mockExperiment,
        interactionType: mockInteractionType,
        questions: [],
      );

      // Assert
      expect(questionnaire.id, '123');
      expect(questionnaire.name, 'Test Questionnaire');
      expect(questionnaire.experiment, mockExperiment);
      expect(questionnaire.interactionType, mockInteractionType);
      expect(questionnaire.questions, isEmpty);
    });

    test('should add questions correctly', () {
      // Arrange
      final questionnaire = Questionnaire(
        id: '123',
        name: 'Test Questionnaire',
        experiment: mockExperiment,
        interactionType: mockInteractionType,
        questions: [],
      );

      final question = Question(
        id: 'q1',
        text: 'Test Question',
        description: 'Test Description',
        index: 0,
        allowMultipleResponse: false,
        allowOpenResponse: false,
        answers: [],
      );

      // Act
      questionnaire.questions!.add(question);

      // Assert
      expect(questionnaire.questions!.length, 1);
      expect(questionnaire.questions!.first.id, 'q1');
      expect(questionnaire.questions!.first.text, 'Test Question');
    });

    test('mock questionnaire should return expected values', () {
      // Arrange
      when(mockQuestionnaire.id).thenReturn('mock-q-123');
      when(mockQuestionnaire.name).thenReturn('Mock Questionnaire');

      // Assert
      expect(mockQuestionnaire.id, 'mock-q-123');
      expect(mockQuestionnaire.name, 'Mock Questionnaire');
    });
  });
}

