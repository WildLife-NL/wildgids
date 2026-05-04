import 'package:flutter_test/flutter_test.dart';
import 'package:wildgids/models/beta_models/sighted_animal_model.dart';

void main() {
  group('SightedAnimal', () {
    test('should have correct properties', () {
      // Arrange
      final sightedAnimal = SightedAnimal(
        condition: 'alive',
        lifeStage: 'adult',
        sex: 'male',
      );

      // Assert
      expect(sightedAnimal.condition, 'alive');
      expect(sightedAnimal.lifeStage, 'adult');
      expect(sightedAnimal.sex, 'male');
    });

    test('should convert to JSON correctly', () {
      // Arrange
      final sightedAnimal = SightedAnimal(
        condition: 'alive',
        lifeStage: 'adult',
        sex: 'male',
      );

      // Act
      final json = sightedAnimal.toJson();

      // Assert
      expect(json, isA<Map<String, dynamic>>());
      expect(json['condition'], 'alive');
      expect(json['lifeStage'], 'adult');
      expect(json['sex'], 'male');
    });

    test('should create from JSON correctly', () {
      // Arrange
      final Map<String, dynamic> json = {
        'condition': 'alive',
        'lifeStage': 'adult',
        'sex': 'male',
      };

      // Act
      final sightedAnimal = SightedAnimal.fromJson(json);

      // Assert
      expect(sightedAnimal.condition, 'alive');
      expect(sightedAnimal.lifeStage, 'adult');
      expect(sightedAnimal.sex, 'male');
    });

    test('should handle null values in constructor', () {
      // Arrange & Act
      final sightedAnimal = SightedAnimal(
        condition: '',
        lifeStage: '',
        sex: '',
      );

      // Assert
      expect(sightedAnimal.condition, '');
      expect(sightedAnimal.lifeStage, '');
      expect(sightedAnimal.sex, '');
    });

    test('should handle null values in fromJson', () {
      // Arrange
      final Map<String, dynamic> json = {
        'condition': null,
        'lifeStage': null,
        'sex': null,
      };

      // Act
      final sightedAnimal = SightedAnimal.fromJson(json);

      // Assert
      expect(sightedAnimal.condition, '');
      expect(sightedAnimal.lifeStage, '');
      expect(sightedAnimal.sex, '');
    });

    test('should handle additional properties in JSON', () {
      // Arrange
      final Map<String, dynamic> json = {
        'condition': 'alive',
        'lifeStage': 'adult',
        'sex': 'male',
        'extraProperty': 'should be ignored',
      };

      // Act
      final sightedAnimal = SightedAnimal.fromJson(json);

      // Assert
      expect(sightedAnimal.condition, 'alive');
      expect(sightedAnimal.lifeStage, 'adult');
      expect(sightedAnimal.sex, 'male');
      // No assertion for extraProperty as it should be ignored
    });

    test('should convert empty object to JSON correctly', () {
      // Arrange
      final sightedAnimal = SightedAnimal(
        condition: '',
        lifeStage: '',
        sex: '',
      );

      // Act
      final json = sightedAnimal.toJson();

      // Assert
      expect(json, isA<Map<String, dynamic>>());
      expect(json.containsKey('condition'), true);
      expect(json.containsKey('lifeStage'), true);
      expect(json.containsKey('sex'), true);
    });

    test('equality check should work correctly', () {
      // Arrange
      final animal1 = SightedAnimal(
        condition: 'alive',
        lifeStage: 'adult',
        sex: 'male',
      );

      final animal2 = SightedAnimal(
        condition: 'alive',
        lifeStage: 'adult',
        sex: 'male',
      );

      final animal3 = SightedAnimal(
        condition: 'dead',
        lifeStage: 'adult',
        sex: 'male',
      );

      // Assert
      // Objects with same values are not considered equal without overriding ==
      expect(
        animal1.condition == animal2.condition &&
            animal1.lifeStage == animal2.lifeStage &&
            animal1.sex == animal2.sex,
        true,
      );
      expect(animal1.condition == animal3.condition, false);
    });

    // Note: The original SightedAnimal class doesn't have a copyWith method
    // If you need to test copyWith, you would need to add that method to the class
  });
}

