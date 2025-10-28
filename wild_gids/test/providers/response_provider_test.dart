import 'package:flutter_test/flutter_test.dart';
import 'package:wildrapport/models/beta_models/response_model.dart';
import 'package:wildrapport/providers/response_provider.dart';

void main() {
  late ResponseProvider responseProvider;

  setUp(() {
    responseProvider = ResponseProvider();
  });

  group('ResponseProvider', () {
    test('should initialize with default values', () {
      expect(responseProvider.answerID, isNull);
      expect(responseProvider.interactionID, isNull);
      expect(responseProvider.questionID, isNull);
      expect(responseProvider.text, isNull);
      expect(responseProvider.response, isNull);
      expect(responseProvider.responses, isEmpty);
      expect(responseProvider.updatingResponse, isFalse);
    });

    test('should set and get response', () {
      // Arrange
      final response = Response(
        answerID: 'answer123',
        interactionID: 'interaction123',
        questionID: 'question123',
        text: 'Test response',
      );

      // Act
      responseProvider.setResponse(response);

      // Assert
      expect(responseProvider.response, equals(response));
    });

    test('should add response to list', () {
      // Arrange
      final response = Response(
        answerID: 'answer123',
        interactionID: 'interaction123',
        questionID: 'question123',
        text: 'Test response',
      );
      bool listenerCalled = false;
      responseProvider.addListener(() {
        listenerCalled = true;
      });

      // Act
      responseProvider.addResponse(response);

      // Assert
      expect(responseProvider.responses, contains(response));
      expect(responseProvider.responses.length, 1);
      // Note: addResponse doesn't call notifyListeners
      expect(listenerCalled, isFalse);
    });

    test('should remove response from list', () {
      // Arrange
      final response = Response(
        answerID: 'answer123',
        interactionID: 'interaction123',
        questionID: 'question123',
        text: 'Test response',
      );
      responseProvider.addResponse(response);
      bool listenerCalled = false;
      responseProvider.addListener(() {
        listenerCalled = true;
      });

      // Act
      responseProvider.removeResponse(response);

      // Assert
      expect(responseProvider.responses, isEmpty);
      // Note: removeResponse doesn't call notifyListeners
      expect(listenerCalled, isFalse);
    });

    test('should set updating response state', () {
      // Arrange
      bool listenerCalled = false;
      responseProvider.addListener(() {
        listenerCalled = true;
      });

      // Act
      responseProvider.setUpdatingResponse(true);

      // Assert
      expect(responseProvider.updatingResponse, isTrue);
      expect(listenerCalled, isTrue);
    });

    test('should update existing response in list', () {
      // Arrange
      final originalResponse = Response(
        answerID: 'answer123',
        interactionID: 'interaction123',
        questionID: 'question123',
        text: 'Original text',
      );
      final updatedResponse = Response(
        answerID: 'answer456',
        interactionID: 'interaction123',
        questionID: 'question123',
        text: 'Updated text',
      );
      responseProvider.addResponse(originalResponse);
      bool listenerCalled = false;
      responseProvider.addListener(() {
        listenerCalled = true;
      });

      // Act
      responseProvider.updateResponse(updatedResponse);

      // Assert
      expect(responseProvider.responses.length, 1);
      expect(responseProvider.responses[0].answerID, 'answer456');
      expect(responseProvider.responses[0].text, 'Updated text');
      expect(listenerCalled, isTrue);
    });

    test('should not update response if questionID does not match', () {
      // Arrange
      final originalResponse = Response(
        answerID: 'answer123',
        interactionID: 'interaction123',
        questionID: 'question123',
        text: 'Original text',
      );
      final updatedResponse = Response(
        answerID: 'answer456',
        interactionID: 'interaction123',
        questionID: 'question456', // Different questionID
        text: 'Updated text',
      );
      responseProvider.addResponse(originalResponse);
      bool listenerCalled = false;
      responseProvider.addListener(() {
        listenerCalled = true;
      });

      // Act
      responseProvider.updateResponse(updatedResponse);

      // Assert
      expect(responseProvider.responses.length, 1);
      expect(responseProvider.responses[0].answerID, 'answer123');
      expect(responseProvider.responses[0].text, 'Original text');
      expect(listenerCalled, isFalse);
    });

    test('should set answerID and notify listeners', () {
      // Arrange
      bool listenerCalled = false;
      responseProvider.addListener(() {
        listenerCalled = true;
      });

      // Act
      responseProvider.setAnswerID('answer123');

      // Assert
      expect(responseProvider.answerID, 'answer123');
      expect(listenerCalled, isTrue);
    });

    test('should clear answerID and notify listeners', () {
      // Arrange
      responseProvider.setAnswerID('answer123');
      bool listenerCalled = false;
      responseProvider.addListener(() {
        listenerCalled = true;
      });

      // Act
      responseProvider.clearAnswerID();

      // Assert
      expect(responseProvider.answerID, isNull);
      expect(listenerCalled, isTrue);
    });

    test('should set interactionID and notify listeners', () {
      // Arrange
      bool listenerCalled = false;
      responseProvider.addListener(() {
        listenerCalled = true;
      });

      // Act
      responseProvider.setInteractionID('interaction123');

      // Assert
      expect(responseProvider.interactionID, 'interaction123');
      expect(listenerCalled, isTrue);
    });

    test('should set questionID and notify listeners', () {
      // Arrange
      bool listenerCalled = false;
      responseProvider.addListener(() {
        listenerCalled = true;
      });

      // Act
      responseProvider.setQuestionID('question123');

      // Assert
      expect(responseProvider.questionID, 'question123');
      expect(listenerCalled, isTrue);
    });

    test('should set text and notify listeners', () {
      // Arrange
      bool listenerCalled = false;
      responseProvider.addListener(() {
        listenerCalled = true;
      });

      // Act
      responseProvider.setText('Test response text');

      // Assert
      expect(responseProvider.text, 'Test response text');
      expect(listenerCalled, isTrue);
    });

    test('should build response from current state', () {
      // Arrange
      responseProvider.setAnswerID('answer123');
      responseProvider.setInteractionID('interaction123');
      responseProvider.setQuestionID('question123');
      responseProvider.setText('Test response text');

      // Act
      final response = responseProvider.buildResponse();

      // Assert
      expect(response.answerID, 'answer123');
      expect(response.interactionID, 'interaction123');
      expect(response.questionID, 'question123');
      expect(response.text, 'Test response text');
    });

    test('should clear response and notify listeners', () {
      // Arrange
      responseProvider.setAnswerID('answer123');
      responseProvider.setInteractionID('interaction123');
      responseProvider.setQuestionID('question123');
      responseProvider.setText('Test response text');
      responseProvider.setUpdatingResponse(true);
      bool listenerCalled = false;
      responseProvider.addListener(() {
        listenerCalled = true;
      });

      // Act
      responseProvider.clearResponse();

      // Assert
      expect(responseProvider.answerID, isNull);
      expect(responseProvider.interactionID, isNull);
      expect(responseProvider.questionID, isNull);
      expect(responseProvider.text, isNull);
      expect(responseProvider.response, isNull);
      expect(responseProvider.updatingResponse, isFalse);
      expect(listenerCalled, isTrue);
    });

    test('should clear responses list', () {
      // Arrange
      final response = Response(
        answerID: 'answer123',
        interactionID: 'interaction123',
        questionID: 'question123',
        text: 'Test response',
      );
      responseProvider.addResponse(response);
      bool listenerCalled = false;
      responseProvider.addListener(() {
        listenerCalled = true;
      });

      // Act
      responseProvider.clearResponsesList();

      // Assert
      expect(responseProvider.responses, isEmpty);
      // Note: clearResponsesList doesn't call notifyListeners
      expect(listenerCalled, isFalse);
    });
  });
}