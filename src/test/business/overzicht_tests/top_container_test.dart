import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildgids/widgets/overzicht/top_container.dart';

//This approach:
//Finds the TopContainer widget
//Looks for Container widgets that are descendants of TopContainer
//Gets the first Container and checks its constraints

void main() {
  Widget createTopContainer() {
    return MaterialApp(
      home: Scaffold(
        body: TopContainer(
          userName: 'Test User',
          height: 285.0,
          welcomeFontSize: 20.0,
          usernameFontSize: 24.0,
        ),
      ),
    );
  }

  group('TopContainer', () {
    testWidgets('should display welcome message and username', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(createTopContainer());

      // Assert
      expect(find.textContaining('Welkom'), findsOneWidget);
      expect(find.text('Test User'), findsOneWidget);
    });

    testWidgets('should display user icon and expected height', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(createTopContainer());

      // Assert - top container now uses a person icon instead of logo image.
      expect(find.byIcon(Icons.person), findsOneWidget);

      // Check container height
      final topContainer = find.byType(TopContainer);
      expect(topContainer, findsOneWidget);

      // Find the Container within TopContainer that has the height set
      final containerFinder =
          find
              .descendant(of: topContainer, matching: find.byType(Container))
              .first;

      final containerWidget = tester.widget<Container>(containerFinder);

      // Check if height is set directly in the container
      expect(
        containerWidget.constraints?.maxHeight ??
            containerWidget.constraints?.minHeight,
        285.0,
      );
    });
  });
}

