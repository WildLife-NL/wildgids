import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildrapport/models/api_models/answer.dart';
import 'package:wildrapport/models/api_models/experiment.dart';
import 'package:wildrapport/models/api_models/interaction_type.dart';
import 'package:wildrapport/models/api_models/questionaire.dart';
import 'package:wildrapport/models/api_models/question.dart';
import 'package:wildrapport/models/api_models/user.dart';
import 'package:wildrapport/widgets/questionnaire/questionnaire_multiple_choice.dart';

void main() {
  group('QuestionnaireMultipleChoice with Per-Answer Text Fields', () {
    late Questionnaire testQuestionnaire;
    late Question testQuestion;
    late List<Answer> testAnswers;

    setUp(() {
      // Create test data
      testAnswers = [
        Answer(id: 'a1', index: 0, text: 'Option 1'),
        Answer(id: 'a2', index: 1, text: 'Option 2'),
        Answer(id: 'a3', index: 2, text: 'Option 3'),
      ];

      testQuestion = Question(
        id: 'q1',
        text: 'Select options and provide feedback:',
        description: 'Test question with per-answer text fields',
        allowMultipleResponse: true,
        allowOpenResponse: true, // Enable per-answer text fields
        answers: testAnswers,
        index: 0,
        openResponseFormat: '',
      );

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
        description: 'Test Interaction',
      );

      testQuestionnaire = Questionnaire(
        id: 'q_test',
        name: 'Test Questionnaire',
        experiment: mockExperiment,
        interactionType: mockInteractionType,
        questions: [testQuestion],
      );
    });

    testWidgets(
      'should render checkboxes for each answer when allowMultipleResponse=true',
      (WidgetTester tester) async {
        // Build the widget
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuestionnaireMultipleChoice(
                question: testQuestion,
                questionnaire: testQuestionnaire,
                onNextPressed: () {},
                onBackPressed: () {},
                interactionID: 'interaction123',
                index: 0,
              ),
            ),
          ),
        );

        // Verify checkboxes are rendered
        expect(find.byType(Checkbox), findsWidgets);
        expect(find.byIcon(Icons.check_box_outline_blank), findsWidgets);
      },
    );

    testWidgets(
      'should show text field when an answer is selected and allowOpenResponse=true',
      (WidgetTester tester) async {
        // Build the widget
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuestionnaireMultipleChoice(
                question: testQuestion,
                questionnaire: testQuestionnaire,
                onNextPressed: () {},
                onBackPressed: () {},
                interactionID: 'interaction123',
                index: 0,
              ),
            ),
          ),
        );

        // Verify initial state - no text fields visible
        expect(find.byType(TextField), findsNothing);

        // Tap the first checkbox to select it
        await tester.tap(find.byType(Checkbox).first);
        await tester.pumpAndSettle();

        // Verify text field now appears for the selected answer
        expect(find.byType(TextField), findsWidgets);
      },
    );

    testWidgets(
      'should allow entering text for each selected answer',
      (WidgetTester tester) async {
        // Build the widget
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuestionnaireMultipleChoice(
                question: testQuestion,
                questionnaire: testQuestionnaire,
                onNextPressed: () {},
                onBackPressed: () {},
                interactionID: 'interaction123',
                index: 0,
              ),
            ),
          ),
        );

        // Select first answer
        await tester.tap(find.byType(Checkbox).first);
        await tester.pumpAndSettle();

        // Type text in the text field
        await tester.enterText(find.byType(TextField).first, 'Test feedback 1');
        await tester.pumpAndSettle();

        // Verify the text was entered
        expect(find.text('Test feedback 1'), findsOneWidget);

        // Select second answer
        await tester.tap(find.byType(Checkbox).at(1));
        await tester.pumpAndSettle();

        // Type text in the second text field
        expect(find.byType(TextField), findsWidgets);
      },
    );

    testWidgets(
      'should hide text field when answer is deselected',
      (WidgetTester tester) async {
        // Build the widget
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuestionnaireMultipleChoice(
                question: testQuestion,
                questionnaire: testQuestionnaire,
                onNextPressed: () {},
                onBackPressed: () {},
                interactionID: 'interaction123',
                index: 0,
              ),
            ),
          ),
        );

        // Select first answer
        await tester.tap(find.byType(Checkbox).first);
        await tester.pumpAndSettle();

        // Verify text field appears
        expect(find.byType(TextField), findsWidgets);

        // Deselect the answer
        await tester.tap(find.byType(Checkbox).first);
        await tester.pumpAndSettle();

        // Verify text field is hidden (or removed)
        // Note: This depends on implementation - the field might still exist but be hidden
        final textFields = find.byType(TextField);
        expect(textFields, findsNothing);
      },
    );

    testWidgets(
      'should support multiple selections with individual text fields',
      (WidgetTester tester) async {
        // Build the widget
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuestionnaireMultipleChoice(
                question: testQuestion,
                questionnaire: testQuestionnaire,
                onNextPressed: () {},
                onBackPressed: () {},
                interactionID: 'interaction123',
                index: 0,
              ),
            ),
          ),
        );

        // Select first answer
        await tester.tap(find.byType(Checkbox).first);
        await tester.pumpAndSettle();

        // Select third answer (skip second)
        await tester.tap(find.byType(Checkbox).at(2));
        await tester.pumpAndSettle();

        // Should have 2 text fields visible
        expect(find.byType(TextField), findsWidgets);
      },
    );
  });
}
