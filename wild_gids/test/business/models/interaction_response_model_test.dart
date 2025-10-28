import 'package:flutter_test/flutter_test.dart';
import 'package:wildrapport/models/beta_models/response_model.dart';

void main() {
  group('Response Model', () {
    test('should have correct properties', () {
      // Arrange
      final response = Response(
        interactionID: 'interaction-123',
        questionID: 'question-456',
        answerID: 'answer-789',
        text: 'Test response text',
      );
      
      // Assert
      expect(response.interactionID, 'interaction-123');
      expect(response.questionID, 'question-456');
      expect(response.answerID, 'answer-789');
      expect(response.text, 'Test response text');
    });
    
    test('should create from JSON correctly', () {
      // Arrange
      final json = {
        'interactionID': 'interaction-123',
        'questionID': 'question-456',
        'answerID': 'answer-789',
        'text': 'Test response text',
      };
      
      // Act
      final response = Response.fromJson(json);
      
      // Assert
      expect(response.interactionID, 'interaction-123');
      expect(response.questionID, 'question-456');
      expect(response.answerID, 'answer-789');
      expect(response.text, 'Test response text');
    });
    
    test('should convert to JSON correctly', () {
      // Arrange
      final response = Response(
        interactionID: 'interaction-123',
        questionID: 'question-456',
        answerID: 'answer-789',
        text: 'Test response text',
      );
      
      // Act
      final json = response.toJson();
      
      // Assert
      expect(json['interactionID'], 'interaction-123');
      expect(json['questionID'], 'question-456');
      expect(json['answerID'], 'answer-789');
      expect(json['text'], 'Test response text');
    });
    
    test('should handle null text field', () {
      // Arrange
      final response = Response(
        interactionID: 'interaction-123',
        questionID: 'question-456',
        answerID: 'answer-789',
      );
      
      // Assert
      expect(response.interactionID, 'interaction-123');
      expect(response.questionID, 'question-456');
      expect(response.answerID, 'answer-789');
      expect(response.text, isNull);
      
      // Act
      final json = response.toJson();
      
      // Assert
      expect(json.containsKey('text'), isFalse);
    });
    
    test('should handle empty answerID', () {
      // Arrange
      final response = Response(
        interactionID: 'interaction-123',
        questionID: 'question-456',
        answerID: '',
        text: 'Test response text',
      );
      
      // Assert
      expect(response.interactionID, 'interaction-123');
      expect(response.questionID, 'question-456');
      expect(response.answerID, '');
      expect(response.text, 'Test response text');
      
      // Act
      final json = response.toJson();
      
      // Assert
      expect(json['answerID'], '');
    });
    
    test('should handle multiple comma-separated answerIDs', () {
      // Arrange
      final response = Response(
        interactionID: 'interaction-123',
        questionID: 'question-456',
        answerID: 'answer-1,answer-2,answer-3',
        text: 'Test response text',
      );
      
      // Assert
      expect(response.interactionID, 'interaction-123');
      expect(response.questionID, 'question-456');
      expect(response.answerID, 'answer-1,answer-2,answer-3');
      
      // Act
      final json = response.toJson();
      
      // Assert
      expect(json['answerID'], 'answer-1,answer-2,answer-3');
    });
    
    test('should handle empty interactionID', () {
      // Arrange
      final response = Response(
        interactionID: "", 
        questionID: 'question-456',
        answerID: 'answer-789',
        text: 'Test response text',
      );
      
      // Assert
      expect(response.interactionID, "");
      expect(response.questionID, 'question-456');
      expect(response.answerID, 'answer-789');
    });
    
    test('should handle empty questionID', () {
      // Arrange
      final response = Response(
        interactionID: 'interaction-123',
        questionID: '', 
        answerID: 'answer-789',
        text: 'Test response text',
      );
      
      // Assert
      expect(response.interactionID, 'interaction-123');
      expect(response.questionID, '');
      expect(response.answerID, 'answer-789');
    });
    
    test('should handle null answerID', () {
      // Arrange
      final response = Response(
        interactionID: 'interaction-123',
        questionID: 'question-456',
        text: 'Test response text',
      );
      
      // Assert
      expect(response.interactionID, 'interaction-123');
      expect(response.questionID, 'question-456');
      expect(response.answerID, isNull);
    });
    
    test('should handle JSON with missing optional fields', () {
      // Arrange
      final json = {
        'interactionID': 'interaction-123',
        'questionID': 'question-456',
        'answerID': 'answer-789',
      };
      
      // Act
      final response = Response.fromJson(json);
      
      // Assert
      expect(response.interactionID, 'interaction-123');
      expect(response.questionID, 'question-456');
      expect(response.answerID, 'answer-789');
      expect(response.text, isNull);
    });
    
    test('should throw when creating from JSON with missing required fields', () {
      // Arrange
      final jsonMissingInteractionID = {
        'questionID': 'question-456',
        'answerID': 'answer-789',
      };
      
      final jsonMissingQuestionID = {
        'interactionID': 'interaction-123',
        'answerID': 'answer-789',
      };
      
      // Act & Assert
      expect(() => Response.fromJson(jsonMissingInteractionID), throwsA(isA<TypeError>()));
      expect(() => Response.fromJson(jsonMissingQuestionID), throwsA(isA<TypeError>()));
      
      // This one should work fine since answerID is optional
      final jsonMissingAnswerID = {
        'interactionID': 'interaction-123',
        'questionID': 'question-456',
      };
      final response = Response.fromJson(jsonMissingAnswerID);
      expect(response.answerID, isNull);
    });
    
    test('should correctly handle text property', () {
      // Arrange
      final response = Response(
        interactionID: 'interaction-123',
        questionID: 'question-456',
        answerID: 'answer-789',
        text: 'Test response text',
      );
      
      // Assert
      expect(response.text, 'Test response text');
    });
    
    test('should handle empty text property', () {
      // Arrange
      final response = Response(
        interactionID: 'interaction-123',
        questionID: 'question-456',
        answerID: 'answer-789',
        text: '',
      );
      
      // Assert
      expect(response.text, '');
    });
    
    test('should handle null text property', () {
      // Arrange
      final response = Response(
        interactionID: 'interaction-123',
        questionID: 'question-456',
        answerID: 'answer-789',
      );
      
      // Assert
      expect(response.text, isNull);
    });
    
    test('should correctly convert to JSON with all properties', () {
      // Arrange
      final response = Response(
        interactionID: 'interaction-123',
        questionID: 'question-456',
        answerID: 'answer-789',
        text: 'Test response text',
      );
      
      // Act
      final json = response.toJson();
      
      // Assert
      expect(json['interactionID'], 'interaction-123');
      expect(json['questionID'], 'question-456');
      expect(json['answerID'], 'answer-789');
      expect(json['text'], 'Test response text');
    });
    
    test('should correctly convert to JSON with optional properties omitted', () {
      // Arrange
      final response = Response(
        interactionID: 'interaction-123',
        questionID: 'question-456',
      );
      
      // Act
      final json = response.toJson();
      
      // Assert
      expect(json['interactionID'], 'interaction-123');
      expect(json['questionID'], 'question-456');
      expect(json['answerID'], isNull);
      expect(json['text'], isNull);
    });
    
    test('should correctly create from JSON with all properties', () {
      // Arrange
      final json = {
        'interactionID': 'interaction-123',
        'questionID': 'question-456',
        'answerID': 'answer-789',
        'text': 'Test response text',
      };
      
      // Act
      final response = Response.fromJson(json);
      
      // Assert
      expect(response.interactionID, 'interaction-123');
      expect(response.questionID, 'question-456');
      expect(response.answerID, 'answer-789');
      expect(response.text, 'Test response text');
    });
    
    test('should correctly create from JSON with only required properties', () {
      // Arrange
      final json = {
        'interactionID': 'interaction-123',
        'questionID': 'question-456',
      };
      
      // Act
      final response = Response.fromJson(json);
      
      // Assert
      expect(response.interactionID, 'interaction-123');
      expect(response.questionID, 'question-456');
      expect(response.answerID, isNull);
      expect(response.text, isNull);
    });
  });
}




