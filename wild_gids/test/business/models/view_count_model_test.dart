import 'package:flutter_test/flutter_test.dart';
import 'package:wildrapport/models/animal_waarneming_models/view_count_model.dart';
import 'package:wildrapport/models/enums/animal_age.dart';

void main() {
  group('ViewCountModel', () {
    test('should initialize with default values', () {
      // Arrange & Act
      final viewCount = ViewCountModel();
      
      // Assert
      expect(viewCount.pasGeborenAmount, 0);
      expect(viewCount.onvolwassenAmount, 0);
      expect(viewCount.volwassenAmount, 0);
      expect(viewCount.unknownAmount, 0);
    });
    
    test('should initialize with provided values', () {
      // Arrange & Act
      final viewCount = ViewCountModel(
        pasGeborenAmount: 1,
        onvolwassenAmount: 2,
        volwassenAmount: 3,
        unknownAmount: 4,
      );
      
      // Assert
      expect(viewCount.pasGeborenAmount, 1);
      expect(viewCount.onvolwassenAmount, 2);
      expect(viewCount.volwassenAmount, 3);
      expect(viewCount.unknownAmount, 4);
    });
    
    group('getAge method', () {
      test('should return pasGeboren when pasGeborenAmount > 0', () {
        // Arrange
        final viewCount = ViewCountModel(pasGeborenAmount: 1);
        
        // Act
        final age = viewCount.getAge();
        
        // Assert
        expect(age, AnimalAge.pasGeboren);
      });
      
      test('should return onvolwassen when onvolwassenAmount > 0 and pasGeborenAmount = 0', () {
        // Arrange
        final viewCount = ViewCountModel(onvolwassenAmount: 1);
        
        // Act
        final age = viewCount.getAge();
        
        // Assert
        expect(age, AnimalAge.onvolwassen);
      });
      
      test('should return volwassen when volwassenAmount > 0 and others = 0', () {
        // Arrange
        final viewCount = ViewCountModel(volwassenAmount: 1);
        
        // Act
        final age = viewCount.getAge();
        
        // Assert
        expect(age, AnimalAge.volwassen);
      });
      
      test('should return onbekend when all amounts = 0', () {
        // Arrange
        final viewCount = ViewCountModel();
        
        // Act
        final age = viewCount.getAge();
        
        // Assert
        expect(age, AnimalAge.onbekend);
      });
      
      test('should return onbekend when only unknownAmount > 0', () {
        // Arrange
        final viewCount = ViewCountModel(unknownAmount: 1);
        
        // Act
        final age = viewCount.getAge();
        
        // Assert
        expect(age, AnimalAge.onbekend);
      });
      
      test('should prioritize pasGeboren over other ages', () {
        // Arrange
        final viewCount = ViewCountModel(
          pasGeborenAmount: 1,
          onvolwassenAmount: 2,
          volwassenAmount: 3,
          unknownAmount: 4,
        );
        
        // Act
        final age = viewCount.getAge();
        
        // Assert
        expect(age, AnimalAge.pasGeboren);
      });
      
      test('should prioritize onvolwassen over volwassen and onbekend', () {
        // Arrange
        final viewCount = ViewCountModel(
          onvolwassenAmount: 2,
          volwassenAmount: 3,
          unknownAmount: 4,
        );
        
        // Act
        final age = viewCount.getAge();
        
        // Assert
        expect(age, AnimalAge.onvolwassen);
      });
    });
    
    group('toJson and fromJson', () {
      test('should convert to JSON correctly', () {
        // Arrange
        final viewCount = ViewCountModel(
          pasGeborenAmount: 1,
          onvolwassenAmount: 2,
          volwassenAmount: 3,
          unknownAmount: 4,
        );
        
        // Act
        final json = viewCount.toJson();
        
        // Assert
        expect(json['pasGeborenAmount'], 1);
        expect(json['onvolwassenAmount'], 2);
        expect(json['volwassenAmount'], 3);
        expect(json['unknownAmount'], 4);
      });
      
      test('should create from JSON correctly', () {
        // Arrange
        final Map<String, dynamic> json = {
          'pasGeborenAmount': 1,
          'onvolwassenAmount': 2,
          'volwassenAmount': 3,
          'unknownAmount': 4,
        };
        
        // Act
        final viewCount = ViewCountModel.fromJson(json);
        
        // Assert
        expect(viewCount.pasGeborenAmount, 1);
        expect(viewCount.onvolwassenAmount, 2);
        expect(viewCount.volwassenAmount, 3);
        expect(viewCount.unknownAmount, 4);
      });
      
      test('should handle missing values in JSON', () {
        // Arrange
        final Map<String, dynamic> json = {
          'pasGeborenAmount': 1,
          // Missing onvolwassenAmount
          'volwassenAmount': 3,
          // Missing unknownAmount
        };
        
        // Act
        final viewCount = ViewCountModel.fromJson(json);
        
        // Assert
        expect(viewCount.pasGeborenAmount, 1);
        expect(viewCount.onvolwassenAmount, 0); // Default value
        expect(viewCount.volwassenAmount, 3);
        expect(viewCount.unknownAmount, 0); // Default value
      });
      
      test('should handle null values in JSON', () {
        // Arrange
        final Map<String, dynamic> json = {
          'pasGeborenAmount': null,
          'onvolwassenAmount': null,
          'volwassenAmount': null,
          'unknownAmount': null,
        };
        
        // Act
        final viewCount = ViewCountModel.fromJson(json);
        
        // Assert
        expect(viewCount.pasGeborenAmount, 0);
        expect(viewCount.onvolwassenAmount, 0);
        expect(viewCount.volwassenAmount, 0);
        expect(viewCount.unknownAmount, 0);
      });
      
      test('should round-trip through JSON correctly', () {
        // Arrange
        final original = ViewCountModel(
          pasGeborenAmount: 1,
          onvolwassenAmount: 2,
          volwassenAmount: 3,
          unknownAmount: 4,
        );
        
        // Act
        final json = original.toJson();
        final recreated = ViewCountModel.fromJson(json);
        
        // Assert
        expect(recreated.pasGeborenAmount, original.pasGeborenAmount);
        expect(recreated.onvolwassenAmount, original.onvolwassenAmount);
        expect(recreated.volwassenAmount, original.volwassenAmount);
        expect(recreated.unknownAmount, original.unknownAmount);
      });
    });
  });
}

