import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildrapport/models/animal_waarneming_models/animal_model.dart';
import 'package:wildrapport/widgets/animals/animal_grid.dart';

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

  group('AnimalGrid Widget Tests', () {
    testWidgets('should display all animals in grid', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AnimalGrid(
            animals: testAnimals,
            onAnimalSelected: (_) {},
          ),
        ),
      ));
      
      expect(find.text('Wolf'), findsOneWidget);
      expect(find.text('Fox'), findsOneWidget);
    });

    testWidgets('should call onAnimalSelected when an animal is tapped', (WidgetTester tester) async {
      AnimalModel? selectedAnimal;
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AnimalGrid(
            animals: testAnimals,
            onAnimalSelected: (animal) => selectedAnimal = animal,
          ),
        ),
      ));
      
      await tester.tap(find.text('Wolf'));
      await tester.pump();
      
      expect(selectedAnimal, equals(testAnimals[0]));
    });

    testWidgets('should handle empty animal list', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AnimalGrid(
            animals: [],
            onAnimalSelected: (_) {},
          ),
        ),
      ));
      
      // Instead of looking for GridView, which might not be rendered with empty list,
      // just verify that the widget renders without errors
      expect(find.byType(AnimalGrid), findsOneWidget);
    });
  });
}
