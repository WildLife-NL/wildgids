import 'package:flutter_test/flutter_test.dart';
import 'package:wildrapport/models/beta_models/belonging_damage_report_model.dart';
import 'package:wildrapport/models/beta_models/possesion_model.dart';

void main() {
  group('BelongingDamageReport Model', () {
    test('should have correct properties', () {
      // Arrange
      final possesion = Possesion(
        possesionID: 'belonging-123',
        possesionName: 'Test Belonging',
        category: 'Test Category',
      );

      final report = BelongingDamageReport(
        possesionDamageReportID: 'report-123',
        possesion: possesion,
        impactedAreaType: 'square-meters',
        impactedArea: 100.0,
        currentImpactDamages: 500.0,
        estimatedTotalDamages: 1000.0,
        description: 'Test damage',
        systemDateTime: DateTime(2023, 5, 15),
      );

      // Assert
      expect(report.possesionDamageReportID, 'report-123');
      expect(report.possesion, possesion);
      expect(report.description, 'Test damage');
      expect(report.systemDateTime, DateTime(2023, 5, 15));
    });

    test('should create from JSON correctly', () {
      // Arrange
      final json = {
        'possesionDamageReportID': 'report-123',
        'belonging': {
          'ID': 'belonging-123',
          'name': 'Test Belonging',
          'category': 'Test Category',
        },
        'impactType': 'square-meters',
        'impactValue': 100.0,
        'estimatedDamage': 500.0,
        'estimatedLoss': 1000.0,
        'description': 'Test damage',
        'systemDateTime': '2023-05-15T00:00:00.000',
      };

      // Act
      final report = BelongingDamageReport.fromJson(json);

      // Assert
      expect(report.possesionDamageReportID, 'report-123');
      expect(report.possesion.possesionID, 'belonging-123');
      expect(report.possesion.possesionName, 'Test Belonging');
      expect(report.possesion.category, 'Test Category');
      expect(report.description, 'Test damage');
      expect(report.systemDateTime, DateTime(2023, 5, 15));
    });

    test('should convert to JSON correctly', () {
      // Arrange
      final possesion = Possesion(
        possesionID: 'belonging-123',
        possesionName: 'Test Belonging',
        category: 'Test Category',
      );

      final report = BelongingDamageReport(
        possesionDamageReportID: 'report-123',
        possesion: possesion,
        impactedAreaType: 'square-meters',
        impactedArea: 100.0,
        currentImpactDamages: 500.0,
        estimatedTotalDamages: 1000.0,
        description: 'Test damage',
        systemDateTime: DateTime(2023, 5, 15),
      );

      // Act
      final json = report.toJson();

      // Assert
      expect(json['possesionDamageReportID'], 'report-123');
      expect(json['belonging']['ID'], 'belonging-123');
      expect(json['belonging']['name'], 'Test Belonging');
      expect(json['belonging']['category'], 'Test Category');
      expect(json['description'], 'Test damage');
      expect(json['systemDateTime'], '2023-05-15T00:00:00.000');
    });

    test('should handle null values correctly', () {
      // Arrange
      final possesion = Possesion(
        possesionID: 'belonging-123',
        possesionName: 'Test Belonging',
        category: 'Test Category',
      );

      final report = BelongingDamageReport(
        possesionDamageReportID: 'report-123',
        possesion: possesion,
        impactedAreaType: 'square-meters',
        impactedArea: 100.0,
        currentImpactDamages: 500.0,
        estimatedTotalDamages: 1000.0,
        description: null,
        systemDateTime: DateTime(2023, 5, 15),
      );

      // Assert
      expect(report.possesionDamageReportID, 'report-123');
      expect(report.possesion, possesion);
      expect(report.description, isNull);
      expect(report.systemDateTime, DateTime(2023, 5, 15));
    });

    test('should handle empty values correctly', () {
      // Arrange
      final possesion = Possesion(
        possesionID: 'belonging-123',
        possesionName: 'Test Belonging',
        category: 'Test Category',
      );

      final report = BelongingDamageReport(
        possesionDamageReportID: 'report-123',
        possesion: possesion,
        impactedAreaType: 'square-meters',
        impactedArea: 100.0,
        currentImpactDamages: 500.0,
        estimatedTotalDamages: 1000.0,
        description: '',
        systemDateTime: DateTime(2023, 5, 15),
      );

      // Assert
      expect(report.possesionDamageReportID, 'report-123');
      expect(report.possesion, possesion);
      expect(report.description, isEmpty);
      expect(report.systemDateTime, DateTime(2023, 5, 15));
    });

    test('should create from JSON with missing fields', () {
      // Arrange
      final json = {
        'possesionDamageReportID': 'report-123',
        'belonging': {
          'ID': 'belonging-123',
          'name': 'Test Belonging',
          'category': 'Test Category',
        },
        'impactType': 'square-meters',
        'impactValue': 100.0,
        'estimatedDamage': 500.0,
        'estimatedLoss': 1000.0,
        'systemDateTime': '2023-05-15T00:00:00.000',
        // description is missing
      };

      // Act
      final report = BelongingDamageReport.fromJson(json);

      // Assert
      expect(report.possesionDamageReportID, 'report-123');
      expect(report.possesion.possesionID, 'belonging-123');
      expect(report.description, isNull);
      expect(report.systemDateTime, DateTime(2023, 5, 15));
    });

    test('should be equal when properties are the same', () {
      // Arrange
      final possesion1 = Possesion(
        possesionID: 'belonging-123',
        possesionName: 'Test Belonging',
        category: 'Test Category',
      );

      final possesion2 = Possesion(
        possesionID: 'belonging-123',
        possesionName: 'Test Belonging',
        category: 'Test Category',
      );

      final report1 = BelongingDamageReport(
        possesionDamageReportID: 'report-123',
        possesion: possesion1,
        impactedAreaType: 'square-meters',
        impactedArea: 100.0,
        currentImpactDamages: 500.0,
        estimatedTotalDamages: 1000.0,
        description: 'Test damage',
        systemDateTime: DateTime(2023, 5, 15),
      );

      final report2 = BelongingDamageReport(
        possesionDamageReportID: 'report-123',
        possesion: possesion2,
        impactedAreaType: 'square-meters',
        impactedArea: 100.0,
        currentImpactDamages: 500.0,
        estimatedTotalDamages: 1000.0,
        description: 'Test damage',
        systemDateTime: DateTime(2023, 5, 15),
      );

      // Assert
      expect(report1.possesionDamageReportID, report2.possesionDamageReportID);
      expect(report1.possesion.possesionID, report2.possesion.possesionID);
      expect(report1.description, report2.description);
      expect(report1.systemDateTime, report2.systemDateTime);
    });

    test('should handle ID being null', () {
      // Arrange
      final possesion = Possesion(
        possesionID: 'belonging-123',
        possesionName: 'Test Belonging',
        category: 'Test Category',
      );

      final report = BelongingDamageReport(
        possesionDamageReportID: null,
        possesion: possesion,
        impactedAreaType: 'square-meters',
        impactedArea: 100.0,
        currentImpactDamages: 500.0,
        estimatedTotalDamages: 1000.0,
        description: 'Test damage',
        systemDateTime: DateTime(2023, 5, 15),
      );

      // Assert
      expect(report.possesionDamageReportID, isNull);
      expect(report.possesion, possesion);
      expect(report.description, 'Test damage');
      expect(report.systemDateTime, DateTime(2023, 5, 15));
    });
  });
}
