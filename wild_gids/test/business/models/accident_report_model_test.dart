import 'package:flutter_test/flutter_test.dart';
import 'package:wildrapport/models/beta_models/accident_report_model.dart';
import 'package:wildrapport/models/beta_models/report_location_model.dart';
import 'package:wildrapport/models/beta_models/sighted_animal_model.dart';

void main() {
  group('AccidentReport Model', () {
    test('should have correct properties', () {
      // Arrange
      final location = ReportLocation(
        latitude: 52.3676,
        longtitude: 4.9041,
      );
      
      final animal = SightedAnimal(
        condition: 'alive',
        lifeStage: 'adult',
        sex: 'male',
      );
      
      final report = AccidentReport(
        accidentReportID: 'accident-123',
        description: 'Deer collision on highway',
        damages: 'Front bumper damaged',
        animals: [animal],
        suspectedSpeciesID: 'Deer',
        userSelectedLocation: location,
        systemLocation: location,
        userSelectedDateTime: DateTime(2023, 5, 15),
        systemDateTime: DateTime.now(),
        intensity: 'Medium',
        urgency: 'High',
      );
      
      // Assert
      expect(report.accidentReportID, 'accident-123');
      expect(report.description, 'Deer collision on highway');
      expect(report.damages, 'Front bumper damaged');
      expect(report.animals?.length, 1);
      expect(report.suspectedSpeciesID, 'Deer');
      expect(report.userSelectedLocation, location);
      expect(report.systemLocation, location);
      expect(report.userSelectedDateTime, DateTime(2023, 5, 15));
      expect(report.intensity, 'Medium');
      expect(report.urgency, 'High');
    });
    
    test('should create from JSON correctly', () {
      // Arrange
      final json = {
        'accidentReportID': 'accident-123',
        'description': 'Deer collision on highway',
        'damages': 'Front bumper damaged',
        'suspectedSpeciesID': 'Deer',
        'userSelectedLocation': {
          'latitude': 52.3676,
          'longtitude': 4.9041,
        },
        'systemLocation': {
          'latitude': 52.3676,
          'longtitude': 4.9041,
        },
        'userSelectedDateTime': '2023-05-15T00:00:00.000',
        'systemDateTime': '2023-05-15T00:00:00.000',
        'animals': [
          {
            'condition': 'alive',
            'lifeStage': 'adult',
            'sex': 'male',
          }
        ],
        'intensity': 'Medium',
        'urgency': 'High',
      };
      
      // Act
      final report = AccidentReport.fromJson(json);
      
      // Assert
      expect(report.accidentReportID, 'accident-123');
      expect(report.description, 'Deer collision on highway');
      expect(report.damages, 'Front bumper damaged');
      expect(report.suspectedSpeciesID, 'Deer');
      expect(report.userSelectedLocation?.latitude, 52.3676);
      expect(report.userSelectedLocation?.longtitude, 4.9041);
      expect(report.systemLocation?.latitude, 52.3676);
      expect(report.systemLocation?.longtitude, 4.9041);
      expect(report.userSelectedDateTime, DateTime(2023, 5, 15));
      expect(report.animals?.length, 1);
      expect(report.intensity, 'Medium');
      expect(report.urgency, 'High');
    });

    test('should convert to JSON correctly', () {
      // Arrange
      final location = ReportLocation(
        latitude: 52.3676,
        longtitude: 4.9041,
      );
      
      final animal = SightedAnimal(
        condition: 'alive',
        lifeStage: 'adult',
        sex: 'male',
      );
      
      final report = AccidentReport(
        accidentReportID: 'accident-123',
        description: 'Deer collision on highway',
        damages: 'Front bumper damaged',
        animals: [animal],
        suspectedSpeciesID: 'Deer',
        userSelectedLocation: location,
        systemLocation: location,
        userSelectedDateTime: DateTime(2023, 5, 15),
        systemDateTime: DateTime(2023, 5, 15),
        intensity: 'Medium',
        urgency: 'High',
      );
      
      // Act
      final json = report.toJson();
      
      // Assert
      expect(json['accidentReportID'], 'accident-123');
      expect(json['estimatedDamage'], 'Front bumper damaged');
      expect(json['involvedAnimals'].length, 1);
      expect(json['involvedAnimals'][0]['condition'], 'alive');
    });

    test('should handle null values correctly', () {
      // Arrange
      final location = ReportLocation(
        latitude: 52.3676,
        longtitude: 4.9041,
      );
      
      final report = AccidentReport(
        accidentReportID: null,
        description: null,
        damages: 'Front bumper damaged',
        animals: [],
        suspectedSpeciesID: null,
        userSelectedLocation: location,
        systemLocation: location,
        userSelectedDateTime: null,
        systemDateTime: DateTime(2023, 5, 15),
        intensity: 'Medium',
        urgency: 'High',
      );
      
      // Assert
      expect(report.accidentReportID, isNull);
      expect(report.description, isNull);
      expect(report.damages, 'Front bumper damaged');
      expect(report.animals, isEmpty);
      expect(report.suspectedSpeciesID, isNull);
      expect(report.userSelectedDateTime, isNull);
    });

    test('should handle missing fields in JSON', () {
      // Arrange
      final json = {
        'accidentReportID': 'accident-123',
        'damages': 'Front bumper damaged',
        'userSelectedLocation': {
          'latitude': 52.3676,
          'longtitude': 4.9041,
        },
        'systemLocation': {
          'latitude': 52.3676,
          'longtitude': 4.9041,
        },
        'systemDateTime': '2023-05-15T00:00:00.000',
        'animals': [],
        'intensity': 'Medium',
        'urgency': 'High',
        // description, userSelectedDateTime, suspectedSpeciesID are missing
      };
      
      // Act
      final report = AccidentReport.fromJson(json);
      
      // Assert
      expect(report.accidentReportID, 'accident-123');
      expect(report.description, isNull);
      expect(report.damages, 'Front bumper damaged');
      expect(report.suspectedSpeciesID, isNull);
      expect(report.userSelectedDateTime, isNull);
      expect(report.animals, isEmpty);
    });

    test('should handle multiple animals correctly', () {
      // Arrange
      final location = ReportLocation(
        latitude: 52.3676,
        longtitude: 4.9041,
      );
      
      final animals = [
        SightedAnimal(condition: 'alive', lifeStage: 'adult', sex: 'male'),
        SightedAnimal(condition: 'injured', lifeStage: 'juvenile', sex: 'female'),
        SightedAnimal(condition: 'deceased', lifeStage: 'adult', sex: 'unknown')
      ];
      
      final report = AccidentReport(
        accidentReportID: 'accident-123',
        description: 'Multiple animal collision',
        damages: 'Severe vehicle damage',
        animals: animals,
        suspectedSpeciesID: 'Multiple',
        userSelectedLocation: location,
        systemLocation: location,
        userSelectedDateTime: DateTime(2023, 5, 15),
        systemDateTime: DateTime(2023, 5, 15),
        intensity: 'High',
        urgency: 'Critical',
      );
      
      // Assert
      expect(report.animals?.length, 3);
      expect(report.animals?[0].condition, 'alive');
      expect(report.animals?[1].lifeStage, 'juvenile');
      expect(report.animals?[2].sex, 'unknown');
      
      // Act
      final json = report.toJson();
      
      // Assert
      expect(json['involvedAnimals'].length, 3);
    });
  });
}

