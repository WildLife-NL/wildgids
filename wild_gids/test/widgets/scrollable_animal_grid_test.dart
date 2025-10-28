import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:wildrapport/models/animal_waarneming_models/animal_model.dart';
import 'package:wildrapport/widgets/animals/scrollable_animal_grid.dart';

void main() {
  final List<AnimalModel> testAnimals = [
    AnimalModel(
      animalId: '1',
      animalName: 'Wolf',
      animalImagePath: 'assets/wolf.png',
      genderViewCounts: [],
    ),
    AnimalModel(
      animalId: '2',
      animalName: 'Fox',
      animalImagePath: 'assets/fox.png',
      genderViewCounts: [],
    ),
  ];

  group('ScrollableAnimalGrid Widget Tests', () {
    testWidgets('should display loading indicator when isLoading is true', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              ScrollableAnimalGrid(
                animals: null,
                isLoading: true,
                error: null,
                scrollController: ScrollController(),
                onAnimalSelected: (_) {},
              ),
            ],
          ),
        ),
      ));
      
      // Look for Lottie animation
      expect(find.byType(Lottie), findsOneWidget);
    });

    testWidgets('should display error message when error is provided', (WidgetTester tester) async {
      const errorMessage = 'Test error';
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              ScrollableAnimalGrid(
                animals: null,
                isLoading: false,
                error: errorMessage,
                scrollController: ScrollController(),
                onAnimalSelected: (_) {},
              ),
            ],
          ),
        ),
      ));
      
      expect(find.text('Error: $errorMessage'), findsOneWidget);
    });

    testWidgets('should display retry button when onRetry is provided with error', (WidgetTester tester) async {
      bool retryPressed = false;
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              ScrollableAnimalGrid(
                animals: null,
                isLoading: false,
                error: 'Error',
                scrollController: ScrollController(),
                onRetry: () => retryPressed = true,
                onAnimalSelected: (_) {},
              ),
            ],
          ),
        ),
      ));
      
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      
      expect(retryPressed, true);
    });

    testWidgets('should display animals when provided', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              ScrollableAnimalGrid(
                animals: testAnimals,
                isLoading: false,
                error: null,
                scrollController: ScrollController(),
                onAnimalSelected: (_) {},
              ),
            ],
          ),
        ),
      ));
      
      expect(find.text('Wolf'), findsOneWidget);
      expect(find.text('Fox'), findsOneWidget);
    });

    testWidgets('should display empty message when animals list is empty', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              ScrollableAnimalGrid(
                animals: [],
                isLoading: false,
                error: null,
                scrollController: ScrollController(),
                onAnimalSelected: (_) {},
              ),
            ],
          ),
        ),
      ));
      
      expect(find.text('Geen dieren gevonden'), findsOneWidget);
    });
  });
}

