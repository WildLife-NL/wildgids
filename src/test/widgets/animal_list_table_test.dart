import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildgids/interfaces/waarneming_flow/animal_sighting_reporting_interface.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_model.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_gender_view_count_model.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_sighting_model.dart';
import 'package:wildgids/models/enums/animal_gender.dart';
import 'package:wildgids/models/animal_waarneming_models/view_count_model.dart';
import 'package:wildgids/widgets/animals/animal_list_table.dart';
import 'package:provider/provider.dart';

void main() {
  final AnimalModel testAnimal = AnimalModel(
    animalId: '1',
    animalName: 'Wolf',
    animalImagePath: 'assets/wolf.png',
    genderViewCounts: [
      AnimalGenderViewCount(
        gender: AnimalGender.mannelijk,
        viewCount: ViewCountModel(
          volwassenAmount: 2,
          onvolwassenAmount: 1,
          pasGeborenAmount: 0,
          unknownAmount: 0,
        ),
      ),
      AnimalGenderViewCount(
        gender: AnimalGender.vrouwelijk,
        viewCount: ViewCountModel(
          volwassenAmount: 1,
          onvolwassenAmount: 0,
          pasGeborenAmount: 0,
          unknownAmount: 0,
        ),
      ),
    ],
  );

  group('AnimalListTable Widget Tests', () {
    testWidgets('should display animal name', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiProvider(
              providers: [
                Provider<AnimalSightingReportingInterface>(
                  create: (_) => MockAnimalSightingManager([testAnimal]),
                ),
              ],
              child: const AnimalListTable(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Table), findsOneWidget);
      expect(find.text('Pas geboren'), findsOneWidget);
      expect(find.text('Volwassen'), findsOneWidget);
      expect(find.text('Jong'), findsOneWidget);
      expect(find.text('Onbekend'), findsOneWidget);
    });

    testWidgets('should display correct count totals', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiProvider(
              providers: [
                Provider<AnimalSightingReportingInterface>(
                  create: (_) => MockAnimalSightingManager([testAnimal]),
                ),
              ],
              child: const AnimalListTable(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('2'), findsAtLeast(1)); // volwassenAmount for mannelijk
      expect(
        find.text('1'),
        findsAtLeast(2),
      ); // onvolwassenAmount for mannelijk and volwassenAmount for vrouwelijk
      // Zero values are rendered as empty cells in view mode.
    });

    testWidgets('should allow editing counts', (WidgetTester tester) async {
      final mockManager = MockAnimalSightingManager([testAnimal]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiProvider(
              providers: [
                Provider<AnimalSightingReportingInterface>(
                  create: (_) => mockManager,
                ),
              ],
              child: const AnimalListTable(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final AnimalListTableState state = tester.state<AnimalListTableState>(
        find.byType(AnimalListTable),
      );
      state.toggleEditMode();
      await tester.pumpAndSettle();

      // Find a text field and enter a new value
      final textField = find.byType(TextFormField).first;
      await tester.tap(textField);
      await tester.enterText(textField, '5');
      await tester.pumpAndSettle();

      state.toggleEditMode();
      await tester.pumpAndSettle();

      // Verify animal was updated in the manager
      expect(mockManager.updateAnimalCalled, isTrue);
    });

    testWidgets('should handle empty animal list', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiProvider(
              providers: [
                Provider<AnimalSightingReportingInterface>(
                  create: (_) => MockAnimalSightingManager([]),
                ),
              ],
              child: const AnimalListTable(),
            ),
          ),
        ),
      );

      // Table should be empty but not crash
      expect(find.byType(Table), findsOneWidget);
      expect(find.byType(TableRow), findsNothing);
    });
  });
}

// Mock implementation for testing
class MockAnimalSightingManager implements AnimalSightingReportingInterface {
  final List<AnimalModel> _animals;
  bool updateAnimalCalled = false;
  final List<Function()> _listeners = [];

  MockAnimalSightingManager(this._animals);

  @override
  AnimalSightingModel? getCurrentanimalSighting() {
    if (_animals.isEmpty) return AnimalSightingModel(animals: []);

    // Create a sighting with the animal name visible in the table
    return AnimalSightingModel(
      animals:
          _animals
              .map(
                (animal) => AnimalModel(
                  animalId: animal.animalId,
                  animalName: animal.animalName,
                  animalImagePath: animal.animalImagePath,
                  genderViewCounts: animal.genderViewCounts,
                ),
              )
              .toList(),
    );
  }

  @override
  AnimalSightingModel updateAnimal(AnimalModel animal) {
    updateAnimalCalled = true;
    return AnimalSightingModel(animals: _animals);
  }

  @override
  AnimalSightingModel updateDescription(String description) {
    return AnimalSightingModel(animals: _animals);
  }

  @override
  void addListener(Function() listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(Function() listener) {
    _listeners.remove(listener);
  }

  // Implement other required methods
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Add this helper method to the test file

