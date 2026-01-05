import 'package:flutter_test/flutter_test.dart';
import 'package:wildrapport/models/api_models/answer.dart';

void main() {
  group('Answer', () {
    test('should have correct properties', () {
      // Arrange
      final answer = Answer(
        id: 'answer-123',
        index: 2,
        text: 'Maybe',
        nextQuestionId: 'question-456',
      );

      // Assert
      expect(answer.id, 'answer-123');
      expect(answer.index, 2);
      expect(answer.text, 'Maybe');
      expect(answer.nextQuestionId, 'question-456');
    });

    test('should create from JSON correctly', () {
      // Arrange
      final json = {
        'ID': 'answer-123',
        'index': 2,
        'text': 'Maybe',
        'nextQuestionID': 'question-456',
      };

      // Act
      final answer = Answer.fromJson(json);

      // Assert
      expect(answer.id, 'answer-123');
      expect(answer.index, 2);
      expect(answer.text, 'Maybe');
      expect(answer.nextQuestionId, 'question-456');
    });

    test('should convert to JSON correctly', () {
      // Arrange
      final answer = Answer(
        id: 'answer-123',
        index: 2,
        text: 'Maybe',
        nextQuestionId: 'question-456',
      );

      // Act
      final json = answer.toJson();

      // Assert
      expect(json['ID'], 'answer-123');
      expect(json['index'], 2);
      expect(json['text'], 'Maybe');
      expect(json['nextQuestionID'], 'question-456');
    });

    test('should handle null nextQuestionId in constructor', () {
      // Arrange & Act
      final answer = Answer(
        id: 'answer-123',
        index: 2,
        text: 'Maybe',
        nextQuestionId: null,
      );

      // Assert
      expect(answer.id, 'answer-123');
      expect(answer.index, 2);
      expect(answer.text, 'Maybe');
      expect(answer.nextQuestionId, isNull);
    });

    test('should handle null nextQuestionId in fromJson', () {
      // Arrange
      final json = {
        'ID': 'answer-123',
        'index': 2,
        'text': 'Maybe',
        'nextQuestionID': null,
      };

      // Act
      final answer = Answer.fromJson(json);

      // Assert
      expect(answer.id, 'answer-123');
      expect(answer.index, 2);
      expect(answer.text, 'Maybe');
      expect(answer.nextQuestionId, isNull);
    });

    test('should handle missing nextQuestionId in fromJson', () {
      // Arrange
      final json = {'ID': 'answer-123', 'index': 2, 'text': 'Maybe'};

      // Act
      final answer = Answer.fromJson(json);

      // Assert
      expect(answer.id, 'answer-123');
      expect(answer.index, 2);
      expect(answer.text, 'Maybe');
      expect(answer.nextQuestionId, isNull);
    });

    test('should handle empty string in text field', () {
      // Arrange
      final answer = Answer(
        id: 'answer-123',
        index: 2,
        text: '',
        nextQuestionId: 'question-456',
      );

      // Act
      final json = answer.toJson();

      // Assert
      expect(answer.text, '');
      expect(json['text'], '');
    });

    test('should handle zero index value', () {
      // Arrange
      final answer = Answer(
        id: 'answer-123',
        index: 0,
        text: 'Maybe',
        nextQuestionId: 'question-456',
      );

      // Act
      final json = answer.toJson();

      // Assert
      expect(answer.index, 0);
      expect(json['index'], 0);
    });

    test('should handle negative index value', () {
      // Arrange
      final answer = Answer(
        id: 'answer-123',
        index: -1,
        text: 'Maybe',
        nextQuestionId: 'question-456',
      );

      // Act
      final json = answer.toJson();

      // Assert
      expect(answer.index, -1);
      expect(json['index'], -1);
    });
  });
}
