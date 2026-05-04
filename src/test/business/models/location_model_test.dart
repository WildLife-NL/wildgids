import 'package:flutter_test/flutter_test.dart';
import 'package:wildgids/models/beta_models/location_model.dart';
import 'package:wildgids/models/enums/location_source.dart';

void main() {
  group('LocationModel', () {
    test('should have correct properties', () {
      // Arrange
      final location = LocationModel(
        latitude: 52.3676,
        longitude: 4.9041,
        source: LocationSource.system,
      );

      // Assert
      expect(location.latitude, 52.3676);
      expect(location.longitude, 4.9041);
      expect(location.source, LocationSource.system);
    });

    test('should convert to JSON correctly', () {
      // Arrange
      final location = LocationModel(
        latitude: 52.3676,
        longitude: 4.9041,
        source: LocationSource.system,
      );

      // Act
      final json = location.toJson();

      // Assert
      expect(json, isA<Map<String, dynamic>>());
      expect(json['latitude'], 52.3676);
      expect(json['longitude'], 4.9041);
      expect(json['source'], LocationSource.system.toString());
    });

    test('should create from JSON correctly', () {
      // Arrange
      final Map<String, dynamic> json = {
        'latitude': 51.9244,
        'longitude': 4.4777,
        'source': 'LocationSource.manual',
      };

      // Act
      final location = LocationModel.fromJson(json);

      // Assert
      expect(location.latitude, 51.9244);
      expect(location.longitude, 4.4777);
      expect(location.source, LocationSource.manual);
    });

    test('should handle unknown source in fromJson', () {
      // Arrange
      final Map<String, dynamic> json = {
        'latitude': 51.9244,
        'longitude': 4.4777,
        'source': 'LocationSource.unknown',
      };

      // Act
      final location = LocationModel.fromJson(json);

      // Assert
      expect(location.latitude, 51.9244);
      expect(location.longitude, 4.4777);
      expect(
        location.source,
        LocationSource.unknown,
      ); // The actual implementation returns unknown
    });
  });
}

