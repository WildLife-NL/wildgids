import 'package:flutter_test/flutter_test.dart';
import 'package:wildrapport/models/beta_models/profile_model.dart';

void main() {
  group('ProfileModel', () {
    
    test('should have correct properties', () {
      // Arrange
      final profileModel = Profile(
        userID: '123',
        email: 'john.doe@example.com',
        gender: 'male',
        userName: 'John Doe',
        postcode: '12345',
      );
      
      // Assert
      expect(profileModel.userID, '123');
      expect(profileModel.userName, 'John Doe');
      expect(profileModel.email, 'john.doe@example.com');
      expect(profileModel.gender, 'male');
      expect(profileModel.postcode, '12345');
    });
    
    test('should handle optional properties correctly', () {
      // Arrange
      final profileModel = Profile(
        userID: '123',
        email: 'john.doe@example.com',
        userName: 'John Doe',
      );
      
      // Assert
      expect(profileModel.userID, '123');
      expect(profileModel.userName, 'John Doe');
      expect(profileModel.email, 'john.doe@example.com');
      expect(profileModel.gender, null);
      expect(profileModel.postcode, null);
    });
    
    test('should convert to JSON correctly', () {
      // Arrange
      final profileModel = Profile(
        userID: '123',
        email: 'john.doe@example.com',
        gender: 'male',
        userName: 'John Doe',
        postcode: '12345',
      );
      
      // Act
      final json = profileModel.toJson();
      
      // Assert
      expect(json, isA<Map<String, dynamic>>());
      expect(json['ID'], '123');
      expect(json['name'], 'John Doe');
      expect(json['email'], 'john.doe@example.com');
      expect(json['gender'], 'male');
      expect(json['postcode'], '12345');
    });
    
    test('should convert to JSON with null optional properties', () {
      // Arrange
      final profileModel = Profile(
        userID: '123',
        email: 'john.doe@example.com',
        userName: 'John Doe',
      );
      
      // Act
      final json = profileModel.toJson();
      
      // Assert
      expect(json, isA<Map<String, dynamic>>());
      expect(json['ID'], '123');
      expect(json['name'], 'John Doe');
      expect(json['email'], 'john.doe@example.com');
      expect(json['gender'], null);
      expect(json['postcode'], null);
    });
    
    test('should create from JSON correctly', () {
      // Arrange
      final Map<String, dynamic> json = {
        'ID': '123',
        'name': 'John Doe',
        'email': 'john.doe@example.com',
        'gender': 'male',
        'postcode': '12345',
      };
      
      // Act
      final profileModel = Profile.fromJson(json);
      
      // Assert
      expect(profileModel.userID, '123');
      expect(profileModel.userName, 'John Doe');
      expect(profileModel.email, 'john.doe@example.com');
      expect(profileModel.gender, 'male');
      expect(profileModel.postcode, '12345');
    });
    
    test('should create from JSON with missing optional properties', () {
      // Arrange
      final Map<String, dynamic> json = {
        'ID': '123',
        'name': 'John Doe',
        'email': 'john.doe@example.com',
      };
      
      // Act
      final profileModel = Profile.fromJson(json);
      
      // Assert
      expect(profileModel.userID, '123');
      expect(profileModel.userName, 'John Doe');
      expect(profileModel.email, 'john.doe@example.com');
      expect(profileModel.gender, null);
      expect(profileModel.postcode, null);
    });
    
    test('should handle empty string values in JSON', () {
      // Arrange
      final Map<String, dynamic> json = {
        'ID': '123',
        'name': '',
        'email': 'john.doe@example.com',
        'gender': '',
        'postcode': '',
      };
      
      // Act
      final profileModel = Profile.fromJson(json);
      
      // Assert
      expect(profileModel.userID, '123');
      expect(profileModel.userName, '');
      expect(profileModel.email, 'john.doe@example.com');
      expect(profileModel.gender, '');
      expect(profileModel.postcode, '');
    });
  });
}


