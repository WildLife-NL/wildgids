import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

Future<void> runQuestionnaireSteps(WidgetTester tester) async {
  await tester.pumpAndSettle(const Duration(seconds: 1));

  expect(find.text('Vragenlijst Openen'), findsOneWidget);
  await tester.tap(find.text('Vragenlijst Openen'));
  await tester.pumpAndSettle(const Duration(seconds: 1));

  expect(find.text('Very Positive'), findsOneWidget);
  await tester.tap(find.text('Very Positive'));
  await tester.pumpAndSettle(const Duration(seconds: 1));

  expect(find.text('Positive'), findsOneWidget);
  await tester.tap(find.text('Positive'));
  await tester.pumpAndSettle(const Duration(seconds: 1));

  await tester.tap(find.text('Volgende'));
  await tester.pumpAndSettle(const Duration(seconds: 1));

  expect(find.text('Negative'), findsOneWidget);
  await tester.tap(find.text('Negative'));
  await tester.pumpAndSettle(const Duration(seconds: 1));

  await tester.tap(find.text('Volgende'));
  await tester.pumpAndSettle(const Duration(seconds: 1));

  expect(find.byKey(const Key('questionnaire-description')), findsOneWidget);
  await tester.enterText(
    find.byKey(const Key('questionnaire-description')),
    'de interactie was erg positief!',
  );
  await tester.pumpAndSettle(const Duration(seconds: 1));

  await tester.tap(find.text('Volgende'));
  await tester.pumpAndSettle(const Duration(seconds: 1));
}
