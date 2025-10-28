import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildrapport/widgets/animals/counter_widget.dart';

void main() {
  group('CounterWidget Tests', () {
    testWidgets('should display initial count', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AnimalCounter(
            name: "Test",
            onCountChanged: (_, count) {},
          ),
        ),
      ));
      
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('should call onCountChanged when + button is pressed', (WidgetTester tester) async {
      int newCount = 0;
      String animalName = "";
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AnimalCounter(
            name: "Test",
            onCountChanged: (name, count) {
              animalName = name;
              newCount = count;
            },
          ),
        ),
      ));
      
      await tester.tap(find.text("+"));
      await tester.pump();
      
      expect(newCount, 1);
      expect(animalName, "Test");
    });

    testWidgets('should call onCountChanged when - button is pressed', (WidgetTester tester) async {
      int newCount = 0;
      String animalName = "";
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AnimalCounter(
            name: "Test",
            onCountChanged: (name, count) {
              animalName = name;
              newCount = count;
            },
          ),
        ),
      ));
      
      // First increment to 1
      await tester.tap(find.text("+"));
      await tester.pump();
      
      // Then decrement back to 0
      await tester.tap(find.text("−"));
      await tester.pump();
      
      expect(newCount, 0);
      expect(animalName, "Test");
    });

    testWidgets('should not allow decrement below 0', (WidgetTester tester) async {
      int newCount = -1;
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AnimalCounter(
            name: "Test",
            onCountChanged: (_, count) => newCount = count,
          ),
        ),
      ));
      
      await tester.tap(find.text("−"));
      await tester.pump();
      
      // Should still be 0, not -1
      expect(newCount, 0);
    });
  });
}
