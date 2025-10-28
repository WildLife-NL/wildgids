import 'package:flutter_test/flutter_test.dart';
import 'package:wildrapport/models/api_models/species.dart';

void main() {
  group('Species', () {
    test('should have correct properties', () {
      // Arrange
      final species = Species(
        id: 'species-123',
        category: 'mammal',
        commonName: 'Red Fox',
      );
      
      // Assert
      expect(species.id, 'species-123');
      expect(species.category, 'mammal');
      expect(species.commonName, 'Red Fox');
    });
    
    test('should create from JSON correctly', () {
      // Arrange
      final json = {
        'ID': 'species-123',
        'category': 'mammal',
        'commonName': 'Red Fox',
      };
      
      // Act
      final species = Species.fromJson(json);
      
      // Assert
      expect(species.id, 'species-123');
      expect(species.category, 'mammal');
      expect(species.commonName, 'Red Fox');
    });
    
    test('should convert to JSON correctly', () {
      // Arrange
      final species = Species(
        id: 'species-123',
        category: 'mammal',
        commonName: 'Red Fox',
      );
      
      // Act
      final json = species.toJson();
      
      // Assert
      expect(json['id'], 'species-123');
      expect(json['category'], 'mammal');
      expect(json['commonName'], 'Red Fox');
    });
  });
}
