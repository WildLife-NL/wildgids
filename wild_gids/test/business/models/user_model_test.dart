import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:wildrapport/models/api_models/user.dart';
import '../mock_generator.mocks.dart';

void main() {
  group('User Model', () {
    late MockUser mockUser;

    setUp(() {
      mockUser = MockUser();
    });

    test('should convert to JSON correctly', () {
      // Arrange
      final user = User(
        id: '123',
        email: 'test@example.com',
        name: 'Test User',
      );

      // Act
      final json = user.toJson();

      // Assert
      expect(json, isA<Map<String, dynamic>>());
      expect(json['id'], '123');
      expect(json['email'], 'test@example.com');
      expect(json['name'], 'Test User');
    });

    test('User Model should create from JSON correctly', () {
      // Arrange
      final Map<String, dynamic> userData = {
        'userID': '123', // Changed from 'id' to 'userID'
        'name': 'Test User',
        'email': 'test@example.com',
        // Add any other required fields
      };

      // Act
      final user = User.fromJson(userData);

      // Assert
      expect(user.id, '123');
      expect(user.name, 'Test User');
      expect(user.email, 'test@example.com');
      // Add assertions for other fields
    });

    test('mock user should return expected values', () {
      // Arrange
      when(mockUser.id).thenReturn('mock-id-123');
      when(mockUser.toJson()).thenReturn({
        'id': 'mock-id-123',
        'email': 'mock@example.com',
        'name': 'Mock User',
      });

      // Assert
      expect(mockUser.id, 'mock-id-123');
      expect(mockUser.toJson(), contains('id'));
      expect(mockUser.toJson()['id'], 'mock-id-123');
    });
  });
}
