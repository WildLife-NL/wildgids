import 'package:flutter_test/flutter_test.dart';
import 'package:wildrapport/models/api_models/user.dart';

void main() {
  group('User', () {
    test('should have correct properties', () {
      // Arrange
      final user = User(
        id: 'user-123',
        email: 'test@example.com',
        name: 'Test User',
      );
      
      // Assert
      expect(user.id, 'user-123');
      expect(user.email, 'test@example.com');
      expect(user.name, 'Test User');
    });
    
    test('should create from JSON correctly', () {
      // Arrange
      final json = {
        'userID': 'user-123',  // Changed from 'id' to 'userID'
        'email': 'test@example.com',
        'name': 'Test User',
      };
      
      // Act
      final user = User.fromJson(json);
      
      // Assert
      expect(user.id, 'user-123');
      expect(user.email, 'test@example.com');
      expect(user.name, 'Test User');
    });
    
    test('should convert to JSON correctly', () {
      // Arrange
      final user = User(
        id: 'user-123',
        email: 'test@example.com',
        name: 'Test User',
      );
      
      // Act
      final json = user.toJson();
      
      // Assert
      expect(json['id'], 'user-123');
      expect(json['email'], 'test@example.com');
      expect(json['name'], 'Test User');
    });
    
    test('should handle null email in constructor', () {
      // Arrange & Act
      final user = User(
        id: 'user-123',
        email: null,
        name: 'Test User',
      );
      
      // Assert
      expect(user.id, 'user-123');
      expect(user.email, isNull);
      expect(user.name, 'Test User');
    });
    
    test('should handle null name in constructor', () {
      // Arrange & Act
      final user = User(
        id: 'user-123',
        email: 'test@example.com',
        name: null,
      );
      
      // Assert
      expect(user.id, 'user-123');
      expect(user.email, 'test@example.com');
      expect(user.name, isNull);
    });
    
    test('should handle null values in fromJson', () {
      // Arrange
      final json = {
        'userID': 'user-123',  // Changed from 'id' to 'userID'
        'email': null,
        'name': null,
      };
      
      // Act
      final user = User.fromJson(json);
      
      // Assert
      expect(user.id, 'user-123');
      expect(user.email, "");  // The test expects empty string but gets null
      expect(user.name, "");   // The test expects empty string but gets null
    });
  });
}



