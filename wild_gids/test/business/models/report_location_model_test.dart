import 'package:flutter_test/flutter_test.dart';
import 'package:wildrapport/models/beta_models/report_location_model.dart';

void main() {
  group('ReportLocation Model Tests', () {
    test('should have correct properties', () {
      // Arrange
      final location = ReportLocation(
        latitude: 52.3676,
        longtitude: 4.9041,
        cityName: 'Amsterdam',
        streetName: 'Main Street',
        houseNumber: '123',
      );

      // Assert
      expect(location.latitude, 52.3676);
      expect(location.longtitude, 4.9041);
      expect(location.cityName, 'Amsterdam');
      expect(location.streetName, 'Main Street');
      expect(location.houseNumber, '123');
    });

    test('should create from JSON correctly', () {
      // Arrange
      final json = {
        'latitude': 52.3676,
        'longtitude': 4.9041,
        'cityName': 'Amsterdam',
        'streetName': 'Main Street',
        'houseNumber': '123',
      };

      // Act
      final location = ReportLocation.fromJson(json);

      // Assert
      expect(location.latitude, 52.3676);
      expect(location.longtitude, 4.9041);
      expect(location.cityName, 'Amsterdam');
      expect(location.streetName, 'Main Street');
      expect(location.houseNumber, '123');
    });

    test('should convert to JSON correctly', () {
      // Arrange
      final location = ReportLocation(
        latitude: 52.3676,
        longtitude: 4.9041,
        cityName: 'Amsterdam',
        streetName: 'Main Street',
        houseNumber: '123',
      );

      // Act
      final json = location.toJson();

      // Assert
      expect(json['latitude'], 52.3676);
      expect(json['longtitude'], 4.9041);
      expect(json['cityName'], 'Amsterdam');
      expect(json['streetName'], 'Main Street');
      expect(json['houseNumber'], '123');
    });

    test('should handle null values correctly', () {
      // Arrange
      final location = ReportLocation(
        latitude: null,
        longtitude: null,
        cityName: null,
        streetName: null,
        houseNumber: null,
      );

      // Assert
      expect(location.latitude, isNull);
      expect(location.longtitude, isNull);
      expect(location.cityName, isNull);
      expect(location.streetName, isNull);
      expect(location.houseNumber, isNull);
    });

    test('should handle partial null values correctly', () {
      // Arrange
      final location = ReportLocation(
        latitude: 52.3676,
        longtitude: 4.9041,
        cityName: null,
        streetName: null,
        houseNumber: null,
      );

      // Assert
      expect(location.latitude, 52.3676);
      expect(location.longtitude, 4.9041);
      expect(location.cityName, isNull);
      expect(location.streetName, isNull);
      expect(location.houseNumber, isNull);
    });

    test('should create from JSON with missing fields', () {
      // Arrange
      final json = {
        'latitude': 52.3676,
        'longtitude': 4.9041,
        // cityName, streetName, and houseNumber are missing
      };

      // Act
      final location = ReportLocation.fromJson(json);

      // Assert
      expect(location.latitude, 52.3676);
      expect(location.longtitude, 4.9041);
      expect(location.cityName, isNull);
      expect(location.streetName, isNull);
      expect(location.houseNumber, isNull);
    });

    test('should handle empty string values correctly', () {
      // Arrange
      final location = ReportLocation(
        latitude: 52.3676,
        longtitude: 4.9041,
        cityName: '',
        streetName: '',
        houseNumber: '',
      );

      // Assert
      expect(location.latitude, 52.3676);
      expect(location.longtitude, 4.9041);
      expect(location.cityName, isEmpty);
      expect(location.streetName, isEmpty);
      expect(location.houseNumber, isEmpty);
    });

    test('should convert to JSON with null values correctly', () {
      // Arrange
      final location = ReportLocation(
        latitude: null,
        longtitude: null,
        cityName: null,
        streetName: null,
        houseNumber: null,
      );

      // Act
      final json = location.toJson();

      // Assert
      expect(json['latitude'], isNull);
      expect(json['longtitude'], isNull);
      expect(json['cityName'], isNull);
      expect(json['streetName'], isNull);
      expect(json['houseNumber'], isNull);
    });

    test('should be equal when properties are the same', () {
      // Arrange
      final location1 = ReportLocation(
        latitude: 52.3676,
        longtitude: 4.9041,
        cityName: 'Amsterdam',
        streetName: 'Main Street',
        houseNumber: '123',
      );

      final location2 = ReportLocation(
        latitude: 52.3676,
        longtitude: 4.9041,
        cityName: 'Amsterdam',
        streetName: 'Main Street',
        houseNumber: '123',
      );

      // Assert
      expect(location1.latitude, location2.latitude);
      expect(location1.longtitude, location2.longtitude);
      expect(location1.cityName, location2.cityName);
      expect(location1.streetName, location2.streetName);
      expect(location1.houseNumber, location2.houseNumber);
    });
  });
}
