import 'package:flutter_test/flutter_test.dart';
import 'package:wildgids/models/api_models/living_labs.dart';
import 'package:wildgids/models/api_models/location.dart';

void main() {
  group('LivingLabs', () {
    test('should have correct properties', () {
      // Arrange
      final livingLab = LivingLabs(
        id: 'np-zuid-kennemerland',
        name: 'Nationaal Park Zuid-Kennemerland',
        commonName: 'Zuid-Kennemerland',
        definition: [
          Location(latitude: 52.4280, longitude: 4.5400),
          Location(latitude: 52.4100, longitude: 4.6000),
        ],
      );

      // Assert
      expect(livingLab.id, 'np-zuid-kennemerland');
      expect(livingLab.name, 'Nationaal Park Zuid-Kennemerland');
      expect(livingLab.commonName, 'Zuid-Kennemerland');
      expect(livingLab.definition!.length, 2);
      expect(livingLab.definition![0].latitude, 52.4280);
      expect(livingLab.definition![0].longitude, 4.5400);
    });

    test('should create from JSON correctly', () {
      // Arrange
      final json = {
        'ID': 'np-zuid-kennemerland',
        'name': 'Nationaal Park Zuid-Kennemerland',
        'commonName': 'Zuid-Kennemerland',
        'definition': [
          {'latitude': 52.4280, 'longitude': 4.5400},
          {'latitude': 52.4100, 'longitude': 4.6000},
        ],
      };

      // Act
      final livingLab = LivingLabs.fromJson(json);

      // Assert
      expect(livingLab.id, 'np-zuid-kennemerland');
      expect(livingLab.name, 'Nationaal Park Zuid-Kennemerland');
      expect(livingLab.commonName, 'Zuid-Kennemerland');
      expect(livingLab.definition!.length, 2);
      expect(livingLab.definition![0].latitude, 52.4280);
      expect(livingLab.definition![0].longitude, 4.5400);
    });

    test('should convert to JSON correctly', () {
      // Arrange
      final livingLab = LivingLabs(
        id: 'np-zuid-kennemerland',
        name: 'Nationaal Park Zuid-Kennemerland',
        commonName: 'Zuid-Kennemerland',
        definition: [
          Location(latitude: 52.4280, longitude: 4.5400),
          Location(latitude: 52.4100, longitude: 4.6000),
        ],
      );

      // Act
      final json = livingLab.toJson();

      // Assert
      expect(json['ID'], 'np-zuid-kennemerland');
      expect(json['name'], 'Nationaal Park Zuid-Kennemerland');
      expect(json['commonName'], 'Zuid-Kennemerland');
      expect(json['definition'], isA<List>());
      expect(json['definition'].length, 2);
      expect(json['definition'][0]['latitude'], 52.4280);
      expect(json['definition'][0]['longitude'], 4.5400);
    });

    test('should handle null definition in constructor', () {
      // Arrange & Act
      final livingLab = LivingLabs(
        id: 'test-id',
        name: 'Test Name',
        commonName: 'Test',
        definition: null,
      );

      // Assert
      expect(livingLab.id, 'test-id');
      expect(livingLab.definition, isNull);
    });

    test('should handle null definition in fromJson', () {
      // Arrange
      final json = {
        'ID': 'test-id',
        'name': 'Test Name',
        'commonName': 'Test',
        'definition': null,
      };

      // Act
      final livingLab = LivingLabs.fromJson(json);

      // Assert
      expect(livingLab.id, 'test-id');
      expect(livingLab.definition, isNull);
    });

    test('should handle null definition in toJson', () {
      // Arrange
      final livingLab = LivingLabs(
        id: 'test-id',
        name: 'Test Name',
        commonName: 'Test',
        definition: null,
      );

      // Act
      final json = livingLab.toJson();

      // Assert
      expect(json['ID'], 'test-id');
      expect(json['definition'], isNull);
    });

    test('should handle empty definition list', () {
      // Arrange
      final livingLab = LivingLabs(
        id: 'test-id',
        name: 'Test Name',
        commonName: 'Test',
        definition: [],
      );

      // Act
      final json = livingLab.toJson();

      // Assert
      expect(livingLab.definition, isEmpty);
      expect(json['definition'], isEmpty);
    });
  });
}

