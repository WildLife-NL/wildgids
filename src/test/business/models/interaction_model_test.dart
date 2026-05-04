import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:wildgids/interfaces/reporting/reportable_interface.dart';
import 'package:wildgids/models/beta_models/interaction_model.dart';
import 'package:wildgids/models/enums/interaction_type.dart';
import 'package:wildgids/models/beta_models/report_factory.dart';
import '../mock_generator.mocks.dart';

class MockSightingReport extends Mock implements Reportable {}

void main() {
  late MockReportable mockReport;

  setUp(() {
    mockReport = MockReportable();
    when(mockReport.toJson()).thenReturn({'test': 'data'});
  });

  group('Interaction Model', () {
    test('should have correct properties', () {
      // Arrange
      final interaction = Interaction(
        interactionType: InteractionType.waarneming,
        userID: 'user-456',
        report: mockReport,
      );

      // Assert
      expect(interaction.interactionType, InteractionType.waarneming);
      expect(interaction.userID, 'user-456');
      expect(interaction.report, mockReport);
    });

    test('should create from JSON with mocked factory', () {
      // Setup
      final mockSightingReport = MockSightingReport();
      final originalFactory = reportFactories['waarneming'];

      // Replace factory temporarily
      reportFactories['waarneming'] = (_) => mockSightingReport;

      // Arrange
      final json = {
        'interactionType': 'waarneming',
        'userID': 'user-456',
        'report': {'test': 'data'},
      };

      // Act
      final interaction = Interaction.fromJson(json);

      // Assert
      expect(interaction.interactionType, InteractionType.waarneming);
      expect(interaction.userID, 'user-456');
      expect(interaction.report, mockSightingReport);

      // Restore original factory
      if (originalFactory != null) {
        reportFactories['waarneming'] = originalFactory;
      }
    });

    test('should convert to JSON correctly', () {
      // Arrange
      final interaction = Interaction(
        interactionType: InteractionType.waarneming,
        userID: 'user-456',
        report: mockReport,
      );

      // Act
      final json = interaction.toJson();

      // Assert
      expect(json['interactionType'], 'waarneming');
      expect(json['userID'], 'user-456');
      expect(json['report'], {'test': 'data'});
    });

    test('should handle report data correctly', () {
      // Arrange - we already set up the mock in setUp()
      when(mockReport.toJson()).thenReturn({
        'description': 'Test description',
        'location': {'latitude': 52.0, 'longitude': 4.0},
      });

      final interaction = Interaction(
        interactionType: InteractionType.waarneming,
        userID: 'user-456',
        report: mockReport,
      );

      // Act & Assert
      expect(interaction.report, isNotNull);
      final reportJson = interaction.report.toJson();
      expect(reportJson, contains('description'));
      expect(reportJson, contains('location'));
    });

    test('should convert to JSON with report data correctly', () {
      // Arrange - we already set up the mock in setUp()
      when(mockReport.toJson()).thenReturn({
        'description': 'Test description',
        'location': {'latitude': 52.0, 'longitude': 4.0},
      });

      final interaction = Interaction(
        interactionType: InteractionType.waarneming,
        userID: 'user-456',
        report: mockReport,
      );

      // Act
      final json = interaction.toJson();

      // Assert
      expect(json['report'], isA<Map>());
      expect(json['report']['description'], 'Test description');
      expect(json['report']['location'], {'latitude': 52.0, 'longitude': 4.0});
    });

    test('should handle null report gracefully', () {
      // This test needs to be updated as Reportable is now required
      // We'll test with a mock report instead
      final interaction = Interaction(
        interactionType: InteractionType.waarneming,
        userID: 'user-456',
        report: mockReport,
      );

      // Assert
      expect(interaction.report, isNotNull);
    });

    test('should handle different interaction types', () {
      // Arrange
      final interactionTypes = [InteractionType.waarneming];

      // Act & Assert
      for (final type in interactionTypes) {
        final interaction = Interaction(
          interactionType: type,
          userID: 'user-456',
          report: mockReport,
        );

        expect(interaction.interactionType, type);
        expect(
          interaction.toJson()['interactionType'],
          type.toString().split('.').last,
        );
      }
    });

    test('should handle empty userID', () {
      // Arrange
      final interaction = Interaction(
        interactionType: InteractionType.waarneming,
        userID: '',
        report: mockReport,
      );

      // Assert
      expect(interaction.userID, isEmpty);
      expect(interaction.toJson()['userID'], isEmpty);
    });

    test('should handle complex report data structures', () {
      // Arrange
      when(mockReport.toJson()).thenReturn({
        'description': 'Complex report',
        'metadata': {
          'tags': ['wildlife', 'deer', 'forest'],
          'counts': {'adults': 2, 'juveniles': 3},
          'conditions': {'weather': 'sunny', 'visibility': 'good'},
        },
        'location': {
          'coordinates': {'latitude': 52.0, 'longitude': 4.0},
          'accuracy': 10.5,
          'locationName': 'Test Forest',
        },
      });

      final interaction = Interaction(
        interactionType: InteractionType.waarneming,
        userID: 'user-456',
        report: mockReport,
      );

      // Act
      final json = interaction.toJson();

      // Assert
      expect(json['report']['metadata']['tags'], contains('wildlife'));
      expect(json['report']['metadata']['counts']['adults'], 2);
      expect(json['report']['location']['locationName'], 'Test Forest');
    });

    test('should handle fromJson for waarneming type', () {
      // Setup
      final mockSightingReport = MockSightingReport();

      // Save original factories
      final originalWaarnemingFactory = reportFactories['waarneming'];

      // Replace factories temporarily
      reportFactories['waarneming'] = (_) => mockSightingReport;

      // Test waarneming only
      final typeMap = {'waarneming': InteractionType.waarneming};

      final reportMap = {'waarneming': mockSightingReport};

      typeMap.forEach((typeString, typeEnum) {
        // Arrange
        final json = {
          'interactionType': typeString,
          'userID': 'user-456',
          'report': {'test': 'data'},
        };

        // Act
        final interaction = Interaction.fromJson(json);

        // Assert
        expect(interaction.interactionType, typeEnum);
        expect(interaction.report, reportMap[typeString]);
      });

      // Restore original factories
      if (originalWaarnemingFactory != null) {
        reportFactories['waarneming'] = originalWaarnemingFactory;
      }
    });

    // Removing test for interactionID as it's not defined in the Interaction class

    // Removing test for timestamp as it's not defined in the Interaction class
  });
}

