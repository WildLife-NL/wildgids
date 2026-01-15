import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import '../mock_generator.mocks.dart';

void main() {
  late MockExperiment mockExperiment;
  late MockUser mockUser;

  setUp(() {
    mockExperiment = MockExperiment();
    mockUser = MockUser();

    // Setup default behavior
    when(mockExperiment.id).thenReturn('exp-1');
    when(mockExperiment.name).thenReturn('Test Experiment');
    when(mockExperiment.description).thenReturn('Test Description');
    when(mockExperiment.start).thenReturn(DateTime(2023, 1, 1));
    when(mockExperiment.end).thenReturn(DateTime(2023, 12, 31));
    when(mockExperiment.user).thenReturn(mockUser);

    when(mockUser.id).thenReturn('user-1');
    when(mockUser.name).thenReturn('Test User');
  });

  group('Experiment Model Tests', () {
    test('should have correct properties', () {
      // Verify the properties
      expect(mockExperiment.id, 'exp-1');
      expect(mockExperiment.name, 'Test Experiment');
      expect(mockExperiment.description, 'Test Description');
      expect(mockExperiment.start, DateTime(2023, 1, 1));
      expect(mockExperiment.end, DateTime(2023, 12, 31));
      expect(mockExperiment.user, mockUser);
      expect(mockExperiment.user.id, 'user-1');
    });

    test('toJson should return correct map', () {
      // Setup mock behavior for toJson
      when(mockExperiment.toJson()).thenReturn({
        'id': 'exp-1',
        'name': 'Test Experiment',
        'description': 'Test Description',
        'start': '2023-01-01T00:00:00.000',
        'end': '2023-12-31T00:00:00.000',
        'user': {'id': 'user-1', 'name': 'Test User'},
      });

      // Verify
      final json = mockExperiment.toJson();
      expect(json['id'], 'exp-1');
      expect(json['name'], 'Test Experiment');
      expect(json['start'], '2023-01-01T00:00:00.000');
      expect(json['end'], '2023-12-31T00:00:00.000');
      expect(json['user']['id'], 'user-1');
    });
  });
}
