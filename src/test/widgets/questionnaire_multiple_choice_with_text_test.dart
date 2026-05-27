import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/models/api_models/answer.dart';
import 'package:wildgids/models/api_models/experiment.dart';
import 'package:wildgids/models/api_models/interaction_type.dart';
import 'package:wildgids/models/api_models/questionaire.dart';
import 'package:wildgids/models/api_models/question.dart';
import 'package:wildgids/models/api_models/user.dart';
import 'package:wildgids/widgets/questionnaire/questionnaire_multiple_choice.dart';
import 'package:wildgids/providers/response_provider.dart';

void main() {
  group('QuestionnaireMultipleChoice with Per-Answer Text Fields', () {
    late Questionnaire testQuestionnaire;
    late Question testQuestion;
    late List<Answer> testAnswers;

    setUp(() {
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
        allowOpenResponse: true,
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

    Future<void> pumpWidgetUnderTest(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider(
              create: (_) => ResponseProvider(),
              child: QuestionnaireMultipleChoice(
                question: testQuestion,
                questionnaire: testQuestionnaire,
                onNextPressed: () {},
                onBackPressed: () {},
                interactionID: 'interaction123',
                index: 0,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    Finder checkboxTiles() => find.byType(CheckboxListTile);

    testWidgets(
      'should render checkboxes for each answer when allowMultipleResponse=true',
      (WidgetTester tester) async {
        await pumpWidgetUnderTest(tester);

        expect(checkboxTiles(), findsNWidgets(testAnswers.length));
      },
    );

    testWidgets(
      'should show text field when an answer is selected and allowOpenResponse=true',
      (WidgetTester tester) async {
        await pumpWidgetUnderTest(tester);

        expect(find.byType(TextField), findsNothing);

        await tester.tap(checkboxTiles().first);
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsOneWidget);
      },
    );

    testWidgets(
      'should allow entering text for each selected answer',
      (WidgetTester tester) async {
        await pumpWidgetUnderTest(tester);

        await tester.tap(checkboxTiles().first);
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).first, 'Test feedback 1');
        await tester.pumpAndSettle();

        expect(find.text('Test feedback 1'), findsOneWidget);

        await tester.tap(checkboxTiles().at(1));
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsNWidgets(2));
      },
    );

    testWidgets(
      'should hide text field when answer is deselected',
      (WidgetTester tester) async {
        await pumpWidgetUnderTest(tester);

        await tester.tap(checkboxTiles().first);
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsOneWidget);

        await tester.tap(checkboxTiles().first);
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsNothing);
      },
    );

    testWidgets(
      'should support multiple selections with individual text fields',
      (WidgetTester tester) async {
        await pumpWidgetUnderTest(tester);

        await tester.tap(checkboxTiles().first);
        await tester.pumpAndSettle();

        await tester.ensureVisible(checkboxTiles().at(2));
        await tester.tap(checkboxTiles().at(2));
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsNWidgets(2));
      },
    );
  });
}
