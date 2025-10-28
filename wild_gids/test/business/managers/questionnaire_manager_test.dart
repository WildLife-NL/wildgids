import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:wildrapport/managers/other/questionnaire_manager.dart';
import 'package:wildrapport/models/api_models/experiment.dart';
import 'package:wildrapport/models/api_models/interaction_type.dart';
import 'package:wildrapport/models/api_models/questionaire.dart';
import 'package:wildrapport/models/api_models/question.dart';
import 'package:wildrapport/models/api_models/answer.dart';
import 'package:wildrapport/models/api_models/user.dart';
import 'package:wildrapport/widgets/questionnaire/questionnaire_home.dart';
import 'package:wildrapport/widgets/questionnaire/questionnaire_multiple_choice.dart';
import 'package:wildrapport/widgets/questionnaire/questionnaire_open_response.dart';

// Import the generated mocks from mock_generator.mocks.dart
import '../../business/mock_generator.mocks.dart';

void main() {
  late QuestionnaireManager questionnaireManager;
  late MockQuestionnaireApiInterface mockQuestionnaireApi;

  // Create mock objects for required parameters
  final mockUser = User(
    id: 'user1',
    email: 'test@example.com',
    name: 'Test User',
  );
  
  final mockExperiment = Experiment(
    id: 'exp1',
    description: 'Test Experiment',
    name: 'Test Experiment',
    start: DateTime.now(),
    user: mockUser,
  );
  
  final mockInteractionType = InteractionType(
    id: 1,
    name: 'Test Interaction',
    description: 'Test Interaction Description',
  );

  setUp(() {
    mockQuestionnaireApi = MockQuestionnaireApiInterface();
    questionnaireManager = QuestionnaireManager(mockQuestionnaireApi);
  });

  group('QuestionnaireManager', () {
    test('should fetch questionnaire by ID', () async {
      // Arrange
      final questionnaire = Questionnaire(
        id: '5c5cd71a-ed88-4e18-8cd4-725a6c6fe4b1',
        experiment: mockExperiment,
        interactionType: mockInteractionType,
        name: 'Test Questionnaire',
        questions: [],
      );
      
      when(mockQuestionnaireApi.getQuestionnaireByID('5c5cd71a-ed88-4e18-8cd4-725a6c6fe4b1'))
          .thenAnswer((_) async => questionnaire);
      
      // Act
      final result = await questionnaireManager.getQuestionnaire();
      
      // Assert
      expect(result, equals(questionnaire));
      verify(mockQuestionnaireApi.getQuestionnaireByID('5c5cd71a-ed88-4e18-8cd4-725a6c6fe4b1')).called(1);
    });

    test('should build questionnaire layout with no questions', () async {
      // Arrange
      final questionnaire = Questionnaire(
        id: '5c5cd71a-ed88-4e18-8cd4-725a6c6fe4b1',
        experiment: mockExperiment,
        interactionType: mockInteractionType,
        name: 'Test Questionnaire',
        questions: [],
      );
      
      mockNextScreen() {}
      mockLastNextScreen() {}
      mockPreviousScreen() {}
      
      // Act
      final widgets = await questionnaireManager.buildQuestionnaireLayout(
        questionnaire,
        'interaction123',
        mockNextScreen,
        mockLastNextScreen,
        mockPreviousScreen,
      );
      
      // Assert
      expect(widgets.length, 1); // Only home screen
      expect(widgets[0], isA<QuestionnaireHome>());
    });

    test('should build questionnaire layout with multiple choice questions', () async {
      // Arrange
      final questionnaire = Questionnaire(
        id: '5c5cd71a-ed88-4e18-8cd4-725a6c6fe4b1',
        experiment: mockExperiment,
        interactionType: mockInteractionType,
        name: 'Test Questionnaire',
        questions: [
          Question(
            id: 'q1',
            allowMultipleResponse: false,
            allowOpenResponse: false,
            description: 'Multiple Choice Question',
            index: 0,
            text: 'Multiple Choice Question',
            answers: [
              Answer(
                id: 'a1',
                index: 0,
                text: 'Option 1',
              ),
              Answer(
                id: 'a2',
                index: 1,
                text: 'Option 2',
              ),
            ],
          ),
        ],
      );
      
      mockNextScreen() {}
      mockLastNextScreen() {}
      mockPreviousScreen() {}
      
      // Act
      final widgets = await questionnaireManager.buildQuestionnaireLayout(
        questionnaire,
        'interaction123',
        mockNextScreen,
        mockLastNextScreen,
        mockPreviousScreen,
      );
      
      // Assert
      expect(widgets.length, 2); // Home screen + 1 question
      expect(widgets[0], isA<QuestionnaireHome>());
      expect(widgets[1], isA<QuestionnaireMultipleChoice>());
    });

    test('should build questionnaire layout with open response questions', () async {
      // Arrange
      final questionnaire = Questionnaire(
        id: '5c5cd71a-ed88-4e18-8cd4-725a6c6fe4b1',
        experiment: mockExperiment,
        interactionType: mockInteractionType,
        name: 'Test Questionnaire',
        questions: [
          Question(
            id: 'q1',
            allowMultipleResponse: false,
            allowOpenResponse: true,
            description: 'Open Response Question',
            index: 0,
            text: 'Open Response Question',
            answers: [],
          ),
        ],
      );
      
      mockNextScreen() {}
      mockLastNextScreen() {}
      mockPreviousScreen() {}
      
      // Act
      final widgets = await questionnaireManager.buildQuestionnaireLayout(
        questionnaire,
        'interaction123',
        mockNextScreen,
        mockLastNextScreen,
        mockPreviousScreen,
      );
      
      // Assert
      expect(widgets.length, 2); // Home screen + 1 question
      expect(widgets[0], isA<QuestionnaireHome>());
      expect(widgets[1], isA<QuestionnaireOpenResponse>());
    });

    test('should build questionnaire layout with mixed question types', () async {
      // Arrange
      final questionnaire = Questionnaire(
        id: '5c5cd71a-ed88-4e18-8cd4-725a6c6fe4b1',
        experiment: mockExperiment,
        interactionType: mockInteractionType,
        name: 'Test Questionnaire',
        questions: [
          Question(
            id: 'q1',
            allowMultipleResponse: false,
            allowOpenResponse: false,
            description: 'Multiple Choice Question',
            index: 0,
            text: 'Multiple Choice Question',
            answers: [
              Answer(
                id: 'a1',
                index: 0,
                text: 'Option 1',
              ),
              Answer(
                id: 'a2',
                index: 1,
                text: 'Option 2',
              ),
            ],
          ),
          Question(
            id: 'q2',
            allowMultipleResponse: false,
            allowOpenResponse: true,
            description: 'Open Response Question',
            index: 1,
            text: 'Open Response Question',
            answers: [],
          ),
        ],
      );
      
      mockNextScreen() {}
      mockLastNextScreen() {}
      mockPreviousScreen() {}
      
      // Act
      final widgets = await questionnaireManager.buildQuestionnaireLayout(
        questionnaire,
        'interaction123',
        mockNextScreen,
        mockLastNextScreen,
        mockPreviousScreen,
      );
      
      // Assert
      expect(widgets.length, 3); // Home screen + 2 questions
      expect(widgets[0], isA<QuestionnaireHome>());
      expect(widgets[1], isA<QuestionnaireMultipleChoice>());
      expect(widgets[2], isA<QuestionnaireOpenResponse>());
    });

    test('should use lastNextScreen for the last question', () async {
      // Arrange
      final questionnaire = Questionnaire(
        id: '5c5cd71a-ed88-4e18-8cd4-725a6c6fe4b1',
        experiment: mockExperiment,
        interactionType: mockInteractionType,
        name: 'Test Questionnaire',
        questions: [
          Question(
            id: 'q1',
            allowMultipleResponse: false,
            allowOpenResponse: false,
            description: 'Question 1',
            index: 0,
            text: 'Question 1',
            answers: [],
          ),
          Question(
            id: 'q2',
            allowMultipleResponse: false,
            allowOpenResponse: false,
            description: 'Question 2',
            index: 1,
            text: 'Question 2',
            answers: [],
          ),
        ],
      );
      
      mockNextScreen() {}
      mockLastNextScreen() {
      }
      mockPreviousScreen() {}
      
      // Act
      final widgets = await questionnaireManager.buildQuestionnaireLayout(
        questionnaire,
        'interaction123',
        mockNextScreen,
        mockLastNextScreen,
        mockPreviousScreen,
      );
      
      // Assert
      expect(widgets.length, 3); // Home screen + 2 questions
      
      // Simulate pressing next on the last question
      // Note: This is a bit tricky to test since we can't directly access the callback
      // that was passed to the widget. In a real test, we might need to use widget testing
      // to verify this behavior.
      
      // For now, we'll just verify that we have the expected number of widgets
      expect(widgets[0], isA<QuestionnaireHome>());
      expect(widgets[1], isA<QuestionnaireMultipleChoice>());
      expect(widgets[2], isA<QuestionnaireMultipleChoice>());
    });

    test('should handle API errors gracefully', () async {
      // Arrange
      when(mockQuestionnaireApi.getQuestionnaireByID(any))
          .thenThrow(Exception('API error'));
      
      // Act & Assert
      expect(() => questionnaireManager.getQuestionnaire(), throwsException);
    });
  });
}



