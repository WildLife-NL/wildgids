import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_sighting_model.dart';
import '../helpers/rapporteren_helpers.dart';
import '../mock_generator.mocks.dart';

void main() {
  late MockAnimalSightingReportingInterface animalSightingManager;

  setUpAll(() async {
    // Setup environment for all tests
    await RapporterenHelpers.setupEnvironment();
  });

  setUp(() {
    // Use a mock manager for unit tests
    animalSightingManager = RapporterenHelpers.getMockAnimalSightingManager();
  });

  group('AnimalSightingReportingInterface', () {
    test('should create animal sighting report', () {
      // Arrange
      when(
        animalSightingManager.createanimalSighting(),
      ).thenReturn(AnimalSightingModel());

      // Act
      final result = animalSightingManager.createanimalSighting();

      // Assert
      expect(result, isA<AnimalSightingModel>());
      verify(animalSightingManager.createanimalSighting()).called(1);
    });

    test('should handle animal sighting creation failure', () {
      // Arrange
      when(
        animalSightingManager.createanimalSighting(),
      ).thenThrow(Exception('Failed to create'));

      // Act & Assert
      expect(
        () => animalSightingManager.createanimalSighting(),
        throwsException,
      );
      verify(animalSightingManager.createanimalSighting()).called(1);
    });
  });
}

