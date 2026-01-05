import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildrapport/widgets/overlay/error_overlay.dart';

void main() {
  group('ErrorOverlay Widget Tests', () {
    testWidgets('should display error message', (WidgetTester tester) async {
      const errorMessage = 'Test error message';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ErrorOverlay(messages: [errorMessage])),
        ),
      );

      expect(find.text(errorMessage), findsOneWidget);
    });

    testWidgets('should show retry button when onRetry is provided', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: ErrorOverlay(messages: ['Error']))),
      );

      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('should not show retry button when onRetry is null', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: ErrorOverlay(messages: ['Error']))),
      );

      expect(find.byType(ElevatedButton), findsNothing);
    });
  });
}
