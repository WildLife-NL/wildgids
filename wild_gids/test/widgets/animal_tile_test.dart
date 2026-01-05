import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_model.dart';
import 'package:wildgids/widgets/animals/animal_tile.dart';

void main() {
  final testAnimal = AnimalModel(
    animalId: '1',
    animalName: 'Wolf',
    animalImagePath: 'assets/wolf.png',
    genderViewCounts: [],
  );

  group('AnimalTile Widget Tests', () {
    testWidgets('should display animal name', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AnimalTile(animal: testAnimal, onTap: () {})),
        ),
      );

      expect(find.text('Wolf'), findsOneWidget);
    });

    testWidgets('should call onTap when pressed', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimalTile(animal: testAnimal, onTap: () => tapped = true),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell).first);
      await tester.pump();

      expect(tapped, true);
    });

    testWidgets('should display animal image', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AnimalTile(animal: testAnimal, onTap: () {})),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
    });
  });
}

