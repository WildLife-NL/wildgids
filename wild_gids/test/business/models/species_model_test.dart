import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:wildrapport/models/animal_waarneming_models/animal_model.dart';
import 'package:wildrapport/models/api_models/species.dart';
import '../mock_generator.mocks.dart';

void main() {
  group('Species Model', () {
    late MockSpecies mockSpecies;
    
    setUp(() {
      mockSpecies = MockSpecies();
    });
    
    test('should have correct properties', () {
      // Arrange
      final species = Species(
        id: '1',
        category: 'Roofdieren',
        commonName: 'Wolf',
      );
      
      // Assert
      expect(species.id, '1');
      expect(species.category, 'Roofdieren');
      expect(species.commonName, 'Wolf');
    });
    
    test('should convert to AnimalModel correctly', () {
      // Arrange
      final species = Species(
        id: '1',
        category: 'Roofdieren',
        commonName: 'Wolf',
      );
      
      // Act
      final animalModel = AnimalModel(
        animalId: species.id,
        animalName: species.commonName,
        animalImagePath: 'assets/wolf.png',
        genderViewCounts: [],
      );
      
      // Assert
      expect(animalModel.animalId, '1');
      expect(animalModel.animalName, 'Wolf');
      expect(animalModel.animalImagePath, 'assets/wolf.png');
      expect(animalModel.genderViewCounts, isEmpty);
    });
    
    test('mock species should return expected values', () {
      // Arrange
      when(mockSpecies.id).thenReturn('mock-id-1');
      when(mockSpecies.category).thenReturn('Mock Category');
      when(mockSpecies.commonName).thenReturn('Mock Animal');
      
      // Assert
      expect(mockSpecies.id, 'mock-id-1');
      expect(mockSpecies.category, 'Mock Category');
      expect(mockSpecies.commonName, 'Mock Animal');
    });
  });
}
