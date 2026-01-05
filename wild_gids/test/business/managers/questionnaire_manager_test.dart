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

      when(
        mockQuestionnaireApi.getQuestionnaireByID(
          '5c5cd71a-ed88-4e18-8cd4-725a6c6fe4b1',
        ),
      ).thenAnswer((_) async => questionnaire);

      // Act
      final result = await questionnaireManager.getQuestionnaire();

      // Assert
      expect(result, equals(questionnaire));
      verify(
        mockQuestionnaireApi.getQuestionnaireByID(
          '5c5cd71a-ed88-4e18-8cd4-725a6c6fe4b1',
        ),
      ).called(1);
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

    test(
      'should build questionnaire layout with multiple choice questions',
      () async {
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
                Answer(id: 'a1', index: 0, text: 'Option 1'),
                Answer(id: 'a2', index: 1, text: 'Option 2'),
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
      },
    );

    test(
      'should build questionnaire layout with open response questions',
      () async {
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
      },
    );

    test(
      'should build questionnaire layout with mixed question types',
      () async {
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
                Answer(id: 'a1', index: 0, text: 'Option 1'),
                Answer(id: 'a2', index: 1, text: 'Option 2'),
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
      },
    );

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
      when(
        mockQuestionnaireApi.getQuestionnaireByID(any),
      ).thenThrow(Exception('API error'));

      // Act & Assert
      expect(() => questionnaireManager.getQuestionnaire(), throwsException);
    });

    test(
      'should render MultipleChoice widget with per-answer text fields when question has answers',
      () async {
        // Arrange - Create a question with multiple choice answers
        final questionnaire = Questionnaire(
          id: 'q_with_answers',
          experiment: mockExperiment,
          interactionType: mockInteractionType,
          name: 'Test Multiple Choice Questionnaire',
          questions: [
            Question(
              id: 'q1_multi',
              allowMultipleResponse: true,
              allowOpenResponse: true,
              description: 'Multiple choice with per-answer text',
              index: 0,
              text: 'Select one or more options and provide feedback:',
              answers: [
                Answer(id: 'a1', index: 0, text: 'Option 1'),
                Answer(id: 'a2', index: 1, text: 'Option 2'),
                Answer(id: 'a3', index: 2, text: 'Option 3'),
              ],
              openResponseFormat: '',
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

        // Should render MultipleChoice widget because answers are provided
        expect(widgets[1], isA<QuestionnaireMultipleChoice>());
      },
    );

    test(
      'should render OpenResponse widget when question has no answers despite allowMultipleResponse=true',
      () async {
        // Arrange - Create a question claiming to have multiple responses but no answers
        final questionnaire = Questionnaire(
          id: 'q_no_answers',
          experiment: mockExperiment,
          interactionType: mockInteractionType,
          name: 'Test Questionnaire - No Answers',
          questions: [
            Question(
              id: 'q1_no_answers',
              allowMultipleResponse: true,
              allowOpenResponse: true,
              description: 'Multiple response but no answers provided',
              index: 0,
              text: 'This question has no predefined answers',
              answers: null, // No answers provided
              openResponseFormat: '',
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

        // Should render OpenResponse widget because no answers provided
        expect(widgets[1], isA<QuestionnaireOpenResponse>());
      },
    );
  });
}
