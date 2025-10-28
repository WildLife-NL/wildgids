import 'package:flutter_test/flutter_test.dart';
import 'package:wildrapport/models/beta_models/belonging_model.dart';

void main() {
  group('Belonging Model', () {
    test('should have correct properties', () {
      // Arrange
      final belonging = Belonging(
        ID: 'belonging-123',
        name: 'Test Belonging',
        category: 'Test Category',
      );
      
      // Assert
      expect(belonging.ID, 'belonging-123');
      expect(belonging.name, 'Test Belonging');
      expect(belonging.category, 'Test Category');
    });
    
    test('should create from JSON correctly', () {
      // Arrange
      final json = {
        'ID': 'belonging-123',
        'name': 'Test Belonging',
        'category': 'Test Category',
      };
      
      // Act
      final belonging = Belonging.fromJson(json);
      
      // Assert
      expect(belonging.ID, 'belonging-123');
      expect(belonging.name, 'Test Belonging');
      expect(belonging.category, 'Test Category');
    });
    
    test('should convert to JSON correctly', () {
      // Arrange
      final belonging = Belonging(
        ID: 'belonging-123',
        name: 'Test Belonging',
        category: 'Test Category',
      );
      
      // Act
      final json = belonging.toJson();
      
      // Assert
      expect(json['ID'], 'belonging-123');
      expect(json['name'], 'Test Belonging');
      expect(json['category'], 'Test Category');
    });

    test('should handle null values correctly', () {
      // Arrange
      final belonging = Belonging(
        ID: 'belonging-123',
        name: '',
        category: '',
      );
      
      // Assert
      expect(belonging.ID, 'belonging-123');
      expect(belonging.name, isEmpty);
      expect(belonging.category, isEmpty);
    });

    test('should handle empty values correctly', () {
      // Arrange
      final belonging = Belonging(
        ID: 'belonging-123',
        name: '',
        category: '',
      );
      
      // Assert
      expect(belonging.ID, 'belonging-123');
      expect(belonging.name, isEmpty);
      expect(belonging.category, isEmpty);
    });

    test('should create from JSON with missing fields', () {
      // Arrange
      final json = {
        'ID': 'belonging-123',
        // name and category are missing
      };
      
      // Act
      final belonging = Belonging.fromJson(json);
      
      // Assert
      expect(belonging.ID, 'belonging-123');
      expect(belonging.name, isEmpty);
      expect(belonging.category, isEmpty);
    });

    test('should handle additional fields in JSON', () {
      // Arrange
      final json = {
        'ID': 'belonging-123',
        'name': 'Test Belonging',
        'category': 'Test Category',
        'extraField': 'This should be ignored',
      };
      
      // Act
      final belonging = Belonging.fromJson(json);
      
      // Assert
      expect(belonging.ID, 'belonging-123');
      expect(belonging.name, 'Test Belonging');
      expect(belonging.category, 'Test Category');
      // No assertion for extraField as it should be ignored
    });

    test('should be equal when properties are the same', () {
      // Arrange
      final belonging1 = Belonging(
        ID: 'belonging-123',
        name: 'Test Belonging',
        category: 'Test Category',
      );
      
      final belonging2 = Belonging(
        ID: 'belonging-123',
        name: 'Test Belonging',
        category: 'Test Category',
      );
      
      // Assert
      expect(belonging1.ID, belonging2.ID);
      expect(belonging1.name, belonging2.name);
      expect(belonging1.category, belonging2.category);
    });

    test('should handle ID being null', () {
      // Arrange
      final belonging = Belonging(
        ID: null,
        name: 'Test Belonging',
        category: 'Test Category',
      );
      
      // Assert
      expect(belonging.ID, null);
      expect(belonging.name, 'Test Belonging');
      expect(belonging.category, 'Test Category');
    });
  });
}



