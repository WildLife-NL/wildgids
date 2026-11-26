import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildgids/models/walk_recording.dart';
import 'package:wildgids/providers/walk_recorder.dart';
import 'package:wildgids/widgets/map/walk_map_widgets.dart';

class ConsentRecorder extends WalkRecorder {
  int starts = 0;
  bool running = false;
  WalkRecording? existing;
  @override
  WalkRecording? get current => existing;
  @override
  bool get recording => running;
  @override
  Future<void> start() async {
    starts++;
    running = true;
  }
}

void main() {
  testWidgets(
    'a trail uses the existing recording consent and cancel starts nothing',
    (tester) async {
      final recorder = ConsentRecorder();
      addTearDown(recorder.dispose);
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder:
                (context) => Scaffold(
                  body: TextButton(
                    onPressed:
                        () async =>
                            result = await requestWalkRecording(
                              context,
                              recorder,
                            ),
                    child: const Text('Begin'),
                  ),
                ),
          ),
        ),
      );
      await tester.tap(find.text('Begin'));
      await tester.pumpAndSettle();
      expect(find.text('Wandeling opnemen?'), findsOneWidget);
      await tester.tap(find.text('Annuleren'));
      await tester.pumpAndSettle();
      expect(recorder.starts, 0);
      expect(result, isFalse);
      await tester.tap(find.text('Begin'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Start wandeling'));
      await tester.pumpAndSettle();
      expect(recorder.starts, 1);
      expect(result, isTrue);
    },
  );

  testWidgets('resuming from a trail preserves the existing walk', (
    tester,
  ) async {
    final recorder =
        ConsentRecorder()
          ..existing = WalkRecording(
            id: 'existing',
            startedAt: DateTime(2026, 11, 19),
          );
    addTearDown(recorder.dispose);
    final original = recorder.current;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder:
              (context) => Scaffold(
                body: TextButton(
                  onPressed: () => requestWalkRecording(context, recorder),
                  child: const Text('Hervat'),
                ),
              ),
        ),
      ),
    );
    await tester.tap(find.text('Hervat'));
    await tester.pumpAndSettle();
    expect(recorder.current, same(original));
    expect(recorder.starts, 1);
    expect(find.byType(AlertDialog), findsNothing);
  });
}
