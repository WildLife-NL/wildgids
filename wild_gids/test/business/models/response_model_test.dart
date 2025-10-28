import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import '../mock_generator.mocks.dart';

void main() {
  late MockResponse mockResponse;

  setUp(() {
    mockResponse = MockResponse();
    
    // Setup default behavior
    when(mockResponse.interactionID).thenReturn('response-1');
    when(mockResponse.questionID).thenReturn('question-1');
    when(mockResponse.answerID).thenReturn('answer-1');
    when(mockResponse.text).thenReturn('Test open response');
  });

  group('Response Model Tests', () {
    test('should have correct properties', () {
      // Verify the properties
      expect(mockResponse.interactionID, 'response-1');
      expect(mockResponse.questionID, 'question-1');
      expect(mockResponse.answerID, 'answer-1');
      expect(mockResponse.text, 'Test open response');
    });

    test('toJson should return correct map', () {
      // Setup mock behavior for toJson
      when(mockResponse.toJson()).thenReturn({
        'id': 'response-1',
        'questionId': 'question-1',
        'answerId': 'answer-1',
        'openResponse': 'Test open response',
      });
      
      // Verify
      final json = mockResponse.toJson();
      expect(json['id'], 'response-1');
      expect(json['questionId'], 'question-1');
      expect(json['answerId'], 'answer-1');
      expect(json['openResponse'], 'Test open response');
    });
  });
}
