import 'package:flutter_test/flutter_test.dart';
import 'package:wildrapport/models/beta_models/possesion_model.dart';

void main() {
  group('Possesion Model Tests', () {
    test('should have correct properties', () {
      // Arrange
      final possesion = Possesion(
        possesionID: 'possesion-123',
        possesionName: 'Test Possesion',
        category: 'Test Category',
      );

      // Assert
      expect(possesion.possesionID, 'possesion-123');
      expect(possesion.possesionName, 'Test Possesion');
      expect(possesion.category, 'Test Category');
    });

    test('should create from JSON correctly', () {
      // Arrange
      final json = {
        'ID': 'possesion-123',
        'name': 'Test Possesion',
        'category': 'Test Category',
      };

      // Act
      final possesion = Possesion.fromJson(json);

      // Assert
      expect(possesion.possesionID, 'possesion-123');
      expect(possesion.possesionName, 'Test Possesion');
      expect(possesion.category, 'Test Category');
    });

    test('should convert to JSON correctly', () {
      // Arrange
      final possesion = Possesion(
        possesionID: 'possesion-123',
        possesionName: 'Test Possesion',
        category: 'Test Category',
      );

      // Act
      final json = possesion.toJson();

      // Assert
      expect(json['ID'], 'possesion-123');
      expect(json['name'], 'Test Possesion');
      expect(json['category'], 'Test Category');
    });

    test('should handle null ID correctly', () {
      // Arrange
      final possesion = Possesion(
        possesionID: null,
        possesionName: 'Test Possesion',
        category: 'Test Category',
      );

      // Assert
      expect(possesion.possesionID, isNull);
      expect(possesion.possesionName, 'Test Possesion');
      expect(possesion.category, 'Test Category');
    });

    test('should handle empty name correctly', () {
      // Arrange
      final possesion = Possesion(
        possesionID: 'possesion-123',
        possesionName: '',
        category: 'Test Category',
      );

      // Assert
      expect(possesion.possesionID, 'possesion-123');
      expect(possesion.possesionName, isEmpty);
      expect(possesion.category, 'Test Category');
    });

    test('should create from JSON with missing fields', () {
      // Arrange
      final json = {
        'ID': 'possesion-123',
        // name and category are missing
      };

      // Act
      final possesion = Possesion.fromJson(json);

      // Assert
      expect(possesion.possesionID, 'possesion-123');
      expect(possesion.possesionName, isNull);
      expect(possesion.category, isNull);
    });

    test('should convert to JSON with null values correctly', () {
      // Arrange
      final possesion = Possesion(
        possesionID: null,
        possesionName: '',
        category: null,
      );

      // Act
      final json = possesion.toJson();

      // Assert
      expect(json['ID'], isNull);
      expect(json['name'], isNull);
      expect(json['category'], isNull);
    });

    test('should be equal when properties are the same', () {
      // Arrange
      final possesion1 = Possesion(
        possesionID: 'possesion-123',
        possesionName: 'Test Possesion',
        category: 'Test Category',
      );

      final possesion2 = Possesion(
        possesionID: 'possesion-123',
        possesionName: 'Test Possesion',
        category: 'Test Category',
      );

      // Assert
      expect(possesion1.possesionID, possesion2.possesionID);
      expect(possesion1.possesionName, possesion2.possesionName);
      expect(possesion1.category, possesion2.category);
    });

    test('should handle different categories correctly', () {
      // Arrange
      final possesion1 = Possesion(
        possesionID: 'possesion-123',
        possesionName: 'Test Possesion',
        category: 'Category A',
      );

      final possesion2 = Possesion(
        possesionID: 'possesion-123',
        possesionName: 'Test Possesion',
        category: 'Category B',
      );

      // Assert
      expect(possesion1.possesionID, possesion2.possesionID);
      expect(possesion1.possesionName, possesion2.possesionName);
      expect(possesion1.category, isNot(possesion2.category));
    });

    test('should create with minimal required properties', () {
      // Arrange
      final possesion = Possesion(possesionName: 'Test Possesion');

      // Assert
      expect(possesion.possesionID, isNull);
      expect(possesion.possesionName, 'Test Possesion');
      expect(possesion.category, isNull);
    });
  });
}
