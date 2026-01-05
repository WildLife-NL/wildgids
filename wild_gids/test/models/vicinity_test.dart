import 'package:flutter_test/flutter_test.dart';
import 'package:wildrapport/models/api_models/vicinity.dart';

void main() {
  group('Vicinity Model Tests', () {
    test('should parse vicinity response from API correctly', () {
      // Example response from /vicinity/me endpoint
      final json = {
        "animals": [
          {
            "ID": "3892eb50-4697-4c72-aadc-32b766bce3c0",
            "location": {"latitude": 51.6978, "longitude": 5.3037},
            "locationTimestamp": "2025-11-26T14:15:22Z",
            "name": "Bambi",
            "species": {
              "ID": "species-123",
              "commonName": "Ree",
              "name": "Capreolus capreolus",
            },
          },
        ],
        "detections": [
          {
            "location": {"latitude": 51.6978, "longitude": 5.3037},
            "sensorID": "camera-001",
            "species": {
              "ID": "species-456",
              "commonName": "Vos",
              "name": "Vulpes vulpes",
            },
            "timestamp": "2025-11-26T12:00:00Z",
          },
        ],
        "interactions": [
          {
            "ID": "interaction-789",
            "location": {"latitude": 51.6978, "longitude": 5.3037},
            "moment": "2025-11-26T10:00:00Z",
            "species": {"commonName": "Wolf"},
            "type": {"ID": 1, "name": "waarneming"},
          },
        ],
      };

      final vicinity = Vicinity.fromJson(json);

      expect(vicinity.animals.length, 1);
      expect(vicinity.detections.length, 1);
      expect(vicinity.interactions.length, 1);

      // Check animal parsing
      final animal = vicinity.animals[0];
      expect(animal.id, "3892eb50-4697-4c72-aadc-32b766bce3c0");
      expect(animal.lat, 51.6978);
      expect(animal.lon, 5.3037);
      expect(animal.speciesName, "Ree");

      // Check detection parsing
      final detection = vicinity.detections[0];
      expect(detection.lat, 51.6978);
      expect(detection.lon, 5.3037);

      // Check interaction parsing
      final interaction = vicinity.interactions[0];
      expect(interaction.id, "interaction-789");
      expect(interaction.lat, 51.6978);
      expect(interaction.lon, 5.3037);
    });

    test('should handle empty arrays gracefully', () {
      final json = {"animals": [], "detections": [], "interactions": []};

      final vicinity = Vicinity.fromJson(json);

      expect(vicinity.animals.length, 0);
      expect(vicinity.detections.length, 0);
      expect(vicinity.interactions.length, 0);
    });

    test('should handle missing fields gracefully', () {
      final json = <String, dynamic>{};

      final vicinity = Vicinity.fromJson(json);

      expect(vicinity.animals.length, 0);
      expect(vicinity.detections.length, 0);
      expect(vicinity.interactions.length, 0);
    });

    test('should skip malformed items and continue parsing others', () {
      final json = {
        "animals": [
          {
            "ID": "valid-animal",
            "location": {"latitude": 51.6978, "longitude": 5.3037},
            "locationTimestamp": "2025-11-26T14:15:22Z",
            "species": {"commonName": "Ree"},
          },
          {
            // Missing required location field
            "ID": "invalid-animal",
            "species": {"commonName": "Vos"},
          },
          {
            "ID": "another-valid-animal",
            "location": {"latitude": 52.0, "longitude": 5.0},
            "locationTimestamp": "2025-11-26T15:00:00Z",
            "species": {"commonName": "Wolf"},
          },
        ],
        "detections": [],
        "interactions": [],
      };

      final vicinity = Vicinity.fromJson(json);

      // Should parse the 2 valid animals and skip the invalid one
      expect(vicinity.animals.length, 2);
      expect(vicinity.animals[0].speciesName, "Ree");
      expect(vicinity.animals[1].speciesName, "Wolf");
    });
  });
}
