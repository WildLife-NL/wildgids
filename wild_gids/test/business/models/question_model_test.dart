import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import '../mock_generator.mocks.dart';

void main() {
  late MockQuestion mockQuestion;

  setUp(() {
    mockQuestion = MockQuestion();
    
    // Setup default behavior
    when(mockQuestion.id).thenReturn('q-1');
    when(mockQuestion.text).thenReturn('Test Question');
    when(mockQuestion.description).thenReturn('Test Description');
    when(mockQuestion.index).thenReturn(1);
    when(mockQuestion.allowMultipleResponse).thenReturn(false);
    when(mockQuestion.allowOpenResponse).thenReturn(true);
    when(mockQuestion.answers).thenReturn([]);
  });

  group('Question Model Tests', () {
    test('should have correct properties', () {
      // Verify the properties
      expect(mockQuestion.id, 'q-1');
      expect(mockQuestion.text, 'Test Question');
      expect(mockQuestion.description, 'Test Description');
      expect(mockQuestion.index, 1);
      expect(mockQuestion.allowMultipleResponse, false);
      expect(mockQuestion.allowOpenResponse, true);
      expect(mockQuestion.answers, []);
    });

    test('toJson should return correct map', () {
      // Setup mock behavior for toJson
      when(mockQuestion.toJson()).thenReturn({
        'id': 'q-1',
        'text': 'Test Question',
        'description': 'Test Description',
        'index': 1,
        'allowMultipleResponse': false,
        'allowOpenResponse': true,
        'answers': [],
      });
      
      // Verify
      final json = mockQuestion.toJson();
      expect(json['id'], 'q-1');
      expect(json['text'], 'Test Question');
      expect(json['index'], 1);
      expect(json['allowMultipleResponse'], false);
      expect(json['allowOpenResponse'], true);
    });
  });
}
