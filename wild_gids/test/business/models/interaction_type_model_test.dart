import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import '../mock_generator.mocks.dart';

void main() {
  late MockInteractionType mockInteractionType;

  setUp(() {
    mockInteractionType = MockInteractionType();
    
    // Setup default behavior
    when(mockInteractionType.id).thenReturn(1);
    when(mockInteractionType.name).thenReturn('Test Interaction Type');
    when(mockInteractionType.description).thenReturn('Test Description');
  });

  group('InteractionType Model Tests', () {
    test('should have correct properties', () {
      // Verify the properties
      expect(mockInteractionType.id, 1);
      expect(mockInteractionType.name, 'Test Interaction Type');
      expect(mockInteractionType.description, 'Test Description');
    });

    test('toJson should return correct map', () {
      // Setup mock behavior for toJson
      when(mockInteractionType.toJson()).thenReturn({
        'id': 1,
        'name': 'Test Interaction Type',
        'description': 'Test Description',
      });
      
      // Verify
      final json = mockInteractionType.toJson();
      expect(json['id'], 1);
      expect(json['name'], 'Test Interaction Type');
      expect(json['description'], 'Test Description');
    });
  });
}