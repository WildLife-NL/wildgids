import 'package:flutter_test/flutter_test.dart';
import 'package:wildrapport/models/beta_models/sighting_report_model.dart';
import 'package:wildrapport/models/beta_models/report_location_model.dart';
import 'package:wildrapport/models/beta_models/sighted_animal_model.dart';

void main() {
  group('SightingReport Model', () {
    test('should have correct properties', () {
      // Arrange
      final location = ReportLocation(
        latitude: 52.3676,
        longtitude: 4.9041,
      );
      
      final sightedAnimal = SightedAnimal(
        condition: 'alive',
        lifeStage: 'adult',
        sex: 'male',
      );
      
      final report = SightingReport(
        animals: [sightedAnimal],
        sightingReportID: 'report-123',
        description: 'Wolf sighting in forest',
        suspectedSpeciesID: 'Wolf',
        userSelectedLocation: location,
        systemLocation: location,
        userSelectedDateTime: DateTime(2023, 5, 15),
        systemDateTime: DateTime.now(),
      );
      
      // Assert
      expect(report.sightingReportID, 'report-123');
      expect(report.suspectedSpeciesID, 'Wolf');
      expect(report.description, 'Wolf sighting in forest');
      expect(report.userSelectedLocation, location);
      expect(report.systemLocation, location);
      expect(report.userSelectedDateTime, DateTime(2023, 5, 15));
      expect(report.animals.first, sightedAnimal);
    });
    
    test('should create from JSON correctly', () {
      // Arrange
      final json = {
        'sightingReportID': 'report-123',
        'suspectedSpeciesID': 'Wolf',
        'description': 'Wolf sighting in forest',
        'place': {
          'latitude': 52.3676,
          'longtitude': 4.9041,
          'cityName': null,
          'streetName': null,
          'houseNumber': null,
        },
        'location': {
          'latitude': 52.3676,
          'longtitude': 4.9041,
          'cityName': null,
          'streetName': null,
          'houseNumber': null,
        },
        'moment': '2023-05-15T00:00:00.000',
        'timestamp': '2023-05-15T00:00:00.000',
        'involvedAnimals': [{
          'condition': 'alive',
          'lifeStage': 'adult',
          'sex': 'male',
        }],
      };
      
      // Act
      final report = SightingReport.fromJson(json);
      
      // Assert
      expect(report.sightingReportID, 'report-123');
      expect(report.suspectedSpeciesID, 'Wolf');
      expect(report.description, 'Wolf sighting in forest');
      expect(report.userSelectedLocation!.latitude, 52.3676);
      expect(report.systemLocation!.longtitude, 4.9041);
      expect(report.userSelectedDateTime, DateTime(2023, 5, 15));
      expect(report.animals.first.condition, 'alive');
      expect(report.animals.first.lifeStage, 'adult');
      expect(report.animals.first.sex, 'male');
    });
    
    test('should convert to JSON correctly', () {
      // Arrange
      final location = ReportLocation(
        latitude: 52.3676,
        longtitude: 4.9041,
      );
      
      final sightedAnimal = SightedAnimal(
        condition: 'alive',
        lifeStage: 'adult',
        sex: 'male',
      );
      
      final report = SightingReport(
        animals: [sightedAnimal],
        sightingReportID: 'report-123',
        suspectedSpeciesID: 'Wolf',
        description: 'Wolf sighting in forest',
        userSelectedLocation: location,
        systemLocation: location,
        userSelectedDateTime: DateTime(2023, 5, 15),
        systemDateTime: DateTime(2023, 5, 15),
      );
      
      // Act
      final json = report.toJson();
      
      // Assert
      expect(json['sightingReportID'], 'report-123');
      expect(json['suspectedSpeciesID'], 'Wolf');
      expect(json['description'], 'Wolf sighting in forest');
      expect(json['place']['latitude'], 52.3676);
      expect(json['location']['longtitude'], 4.9041);
      expect(json['moment'], '2023-05-15T00:00:00.000');
      expect(json['involvedAnimals'][0]['condition'], 'alive');
      expect(json['involvedAnimals'][0]['lifeStage'], 'adult');
      expect(json['involvedAnimals'][0]['sex'], 'male');
    });

    test('should handle null values correctly', () {
      // Arrange
      final location = ReportLocation(
        latitude: 52.3676,
        longtitude: 4.9041,
      );
      
      final report = SightingReport(
        animals: [],
        sightingReportID: 'report-123',
        suspectedSpeciesID: 'Wolf',
        description: null,
        userSelectedLocation: location,
        systemLocation: location,
        userSelectedDateTime: null,
        systemDateTime: DateTime.now(),
      );
      
      // Assert
      expect(report.sightingReportID, 'report-123');
      expect(report.suspectedSpeciesID, 'Wolf');
      expect(report.description, isNull);
      expect(report.userSelectedLocation, location);
      expect(report.userSelectedDateTime, isNull);
      expect(report.animals, isEmpty);
    });

    test('should handle empty values correctly', () {
      // Arrange
      final location = ReportLocation(
        latitude: 52.3676,
        longtitude: 4.9041,
      );
      
      final report = SightingReport(
        animals: [],
        sightingReportID: 'report-123',
        suspectedSpeciesID: 'Wolf',
        description: '',
        userSelectedLocation: location,
        systemLocation: location,
        userSelectedDateTime: DateTime(2023, 5, 15),
        systemDateTime: DateTime.now(),
      );
      
      // Assert
      expect(report.sightingReportID, 'report-123');
      expect(report.suspectedSpeciesID, 'Wolf');
      expect(report.description, isEmpty);
      expect(report.userSelectedLocation, location);
      expect(report.userSelectedDateTime, DateTime(2023, 5, 15));
      expect(report.animals, isEmpty);
    });

    test('should create from JSON with missing fields', () {
      // Arrange
      final json = {
        'sightingReportID': 'report-123',
        'suspectedSpeciesID': 'Wolf',
        'location': {
          'latitude': 52.3676,
          'longtitude': 4.9041,
        },
        'timestamp': '2023-05-15T00:00:00.000',
        'involvedAnimals': [],
        // description, moment, place, and some animals fields are missing
      };
      
      // Act
      final report = SightingReport.fromJson(json);
      
      // Assert
      expect(report.sightingReportID, 'report-123');
      expect(report.suspectedSpeciesID, 'Wolf');
      expect(report.description, isNull);
      expect(report.systemLocation!.latitude, 52.3676);
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
      
      final report = SightingReport(
        animals: animals,
        sightingReportID: 'report-123',
        suspectedSpeciesID: 'Wolf',
        description: 'Wolf sighting',
        userSelectedLocation: location,
        systemLocation: location,
        userSelectedDateTime: DateTime(2023, 5, 15),
        systemDateTime: DateTime.now(),
      );
      
      // Assert
      expect(report.animals.length, 3);
      expect(report.animals[0].condition, 'alive');
      expect(report.animals[1].lifeStage, 'juvenile');
      expect(report.animals[2].sex, 'unknown');
    });
  });
}

