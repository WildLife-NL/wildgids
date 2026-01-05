import 'package:flutter_test/flutter_test.dart';
import 'package:wildrapport/models/animal_waarneming_models/animal_sighting_model.dart';
import 'package:wildrapport/models/animal_waarneming_models/animal_model.dart';
import 'package:wildrapport/models/beta_models/animal_sighting_report_wrapper.dart';
import 'package:wildrapport/models/enums/animal_category.dart';
import 'package:wildrapport/models/beta_models/location_model.dart';
import 'package:wildrapport/models/enums/location_source.dart';
import 'package:wildrapport/models/ui_models/date_time_model.dart';
import 'package:wildrapport/models/enums/animal_condition.dart';
import 'package:wildrapport/models/animal_waarneming_models/animal_gender_view_count_model.dart';
import 'package:wildrapport/models/enums/animal_gender.dart';
import 'package:wildrapport/models/animal_waarneming_models/view_count_model.dart';
import 'package:wildrapport/models/ui_models/image_list_model.dart';

void main() {
  group('AnimalSightingReportWrapper', () {
    test('should have correct properties', () {
      // Arrange
      final animalModel = AnimalModel(
        animalId: '1',
        animalName: 'Wolf',
        animalImagePath: 'assets/wolf.png',
        genderViewCounts: [],
      );

      final sightingModel = AnimalSightingModel(
        animals: [animalModel],
        animalSelected: animalModel,
        category: AnimalCategory.roofdieren,
        description: 'Test description',
        locations: [
          LocationModel(
            latitude: 52.0,
            longitude: 4.0,
            source: LocationSource.system,
          ),
        ],
        dateTime: DateTimeModel(dateTime: DateTime(2023, 1, 1)),
      );

      final reportWrapper = AnimalSightingReportWrapper(sightingModel);

      // Assert
      expect(reportWrapper.sighting, sightingModel);
    });

    test('should convert to JSON correctly', () {
      // Arrange
      final animalModel = AnimalModel(
        animalId: '1',
        animalName: 'Wolf',
        animalImagePath: 'assets/wolf.png',
        genderViewCounts: [],
      );

      final sightingModel = AnimalSightingModel(
        animals: [animalModel],
        animalSelected: animalModel,
        category: AnimalCategory.roofdieren,
        description: 'Test description',
        // Add required fields for API transformation
        locations: [
          LocationModel(
            latitude: 52.0,
            longitude: 4.0,
            source: LocationSource.system,
          ),
          LocationModel(
            latitude: 52.1,
            longitude: 4.1,
            source: LocationSource.manual,
          ),
        ],
        dateTime: DateTimeModel(dateTime: DateTime(2023, 1, 1)),
      );

      final reportWrapper = AnimalSightingReportWrapper(sightingModel);

      // Act
      final json = reportWrapper.toJson();

      // Assert
      expect(json, isA<Map<String, dynamic>>());
      expect(json['description'], 'Test description');
      expect(json['speciesID'], '1');
      expect(json['typeID'], 1);
      expect(json['location'], isNotNull);
      expect(json['place'], isNotNull);
      expect(json['moment'], isNotNull);
      expect(json['reportOfSighting'], isNotNull);
    });

    test('should throw StateError when locations are missing', () {
      // Arrange
      final animalModel = AnimalModel(
        animalId: '1',
        animalName: 'Wolf',
        animalImagePath: 'assets/wolf.png',
        genderViewCounts: [],
      );

      final sightingModel = AnimalSightingModel(
        animals: [animalModel],
        animalSelected: animalModel,
        category: AnimalCategory.roofdieren,
        description: 'Test description',
        // Missing locations
        dateTime: DateTimeModel(dateTime: DateTime(2023, 1, 1)),
      );

      final reportWrapper = AnimalSightingReportWrapper(sightingModel);

      // Act & Assert
      expect(() => reportWrapper.toJson(), throwsStateError);
    });

    test('should throw StateError when dateTime is missing', () {
      // Arrange
      final animalModel = AnimalModel(
        animalId: '1',
        animalName: 'Wolf',
        animalImagePath: 'assets/wolf.png',
        genderViewCounts: [],
      );

      final sightingModel = AnimalSightingModel(
        animals: [animalModel],
        animalSelected: animalModel,
        category: AnimalCategory.roofdieren,
        description: 'Test description',
        locations: [
          LocationModel(
            latitude: 52.0,
            longitude: 4.0,
            source: LocationSource.system,
          ),
          LocationModel(
            latitude: 52.1,
            longitude: 4.1,
            source: LocationSource.manual,
          ),
        ],
        // Missing dateTime
      );

      final reportWrapper = AnimalSightingReportWrapper(sightingModel);

      // Act & Assert
      expect(() => reportWrapper.toJson(), throwsStateError);
    });

    test('should throw StateError when animals list is empty', () {
      // Arrange
      final animalModel = AnimalModel(
        animalId: '1',
        animalName: 'Wolf',
        animalImagePath: 'assets/wolf.png',
        genderViewCounts: [],
      );

      final sightingModel = AnimalSightingModel(
        animals: [], // Empty animals list
        animalSelected: animalModel,
        category: AnimalCategory.roofdieren,
        description: 'Test description',
        locations: [
          LocationModel(
            latitude: 52.0,
            longitude: 4.0,
            source: LocationSource.system,
          ),
          LocationModel(
            latitude: 52.1,
            longitude: 4.1,
            source: LocationSource.manual,
          ),
        ],
        dateTime: DateTimeModel(dateTime: DateTime(2023, 1, 1)),
      );

      final reportWrapper = AnimalSightingReportWrapper(sightingModel);

      // Act & Assert
      expect(() => reportWrapper.toJson(), throwsStateError);
    });

    test('should throw StateError when animalSelected is missing', () {
      // Arrange
      final animalModel = AnimalModel(
        animalId: '1',
        animalName: 'Wolf',
        animalImagePath: 'assets/wolf.png',
        genderViewCounts: [],
      );

      final sightingModel = AnimalSightingModel(
        animals: [animalModel],
        animalSelected: null, // Missing selected animal
        category: AnimalCategory.roofdieren,
        description: 'Test description',
        locations: [
          LocationModel(
            latitude: 52.0,
            longitude: 4.0,
            source: LocationSource.system,
          ),
          LocationModel(
            latitude: 52.1,
            longitude: 4.1,
            source: LocationSource.manual,
          ),
        ],
        dateTime: DateTimeModel(dateTime: DateTime(2023, 1, 1)),
      );

      final reportWrapper = AnimalSightingReportWrapper(sightingModel);

      // Act & Assert
      expect(() => reportWrapper.toJson(), throwsStateError);
    });

    test('should throw StateError when system location is missing', () {
      // Arrange
      final animalModel = AnimalModel(
        animalId: '1',
        animalName: 'Wolf',
        animalImagePath: 'assets/wolf.png',
        genderViewCounts: [],
      );

      final sightingModel = AnimalSightingModel(
        animals: [animalModel],
        animalSelected: animalModel,
        category: AnimalCategory.roofdieren,
        description: 'Test description',
        locations: [
          // Only manual location, missing system location
          LocationModel(
            latitude: 52.1,
            longitude: 4.1,
            source: LocationSource.manual,
          ),
        ],
        dateTime: DateTimeModel(dateTime: DateTime(2023, 1, 1)),
      );

      final reportWrapper = AnimalSightingReportWrapper(sightingModel);

      // Act & Assert
      expect(() => reportWrapper.toJson(), throwsStateError);
    });

    test('should throw StateError when manual location is missing', () {
      // Arrange
      final animalModel = AnimalModel(
        animalId: '1',
        animalName: 'Wolf',
        animalImagePath: 'assets/wolf.png',
        genderViewCounts: [],
      );

      final sightingModel = AnimalSightingModel(
        animals: [animalModel],
        animalSelected: animalModel,
        category: AnimalCategory.roofdieren,
        description: 'Test description',
        locations: [
          // Only system location, missing manual location
          LocationModel(
            latitude: 52.0,
            longitude: 4.0,
            source: LocationSource.system,
          ),
        ],
        dateTime: DateTimeModel(dateTime: DateTime(2023, 1, 1)),
      );

      final reportWrapper = AnimalSightingReportWrapper(sightingModel);

      // Act & Assert
      expect(() => reportWrapper.toJson(), throwsStateError);
    });

    test('should handle complex animal sighting with multiple animals', () {
      // Arrange
      final wolf = AnimalModel(
        animalId: '1',
        animalName: 'Wolf',
        animalImagePath: 'assets/wolf.png',
        genderViewCounts: [
          AnimalGenderViewCount(
            gender: AnimalGender.mannelijk,
            viewCount: ViewCountModel()..volwassenAmount = 2,
          ),
          AnimalGenderViewCount(
            gender: AnimalGender.vrouwelijk,
            viewCount: ViewCountModel()..volwassenAmount = 1,
          ),
        ],
        condition: AnimalCondition.levend,
      );

      final fox = AnimalModel(
        animalId: '2',
        animalName: 'Fox',
        animalImagePath: 'assets/fox.png',
        genderViewCounts: [
          AnimalGenderViewCount(
            gender: AnimalGender.onbekend,
            viewCount: ViewCountModel()..volwassenAmount = 3,
          ),
        ],
        condition: AnimalCondition.levend,
      );

      final sightingModel = AnimalSightingModel(
        animals: [wolf, fox],
        animalSelected: wolf,
        category: AnimalCategory.roofdieren,
        description: 'Pack of wolves and foxes spotted near the forest',
        locations: [
          LocationModel(
            latitude: 52.0,
            longitude: 4.0,
            source: LocationSource.system,
          ),
          LocationModel(
            latitude: 52.1,
            longitude: 4.1,
            source: LocationSource.manual,
          ),
        ],
        dateTime: DateTimeModel(dateTime: DateTime(2023, 1, 1, 14, 30)),
        images: ImageListModel(
          imagePaths: ['path/to/image1.jpg', 'path/to/image2.jpg'],
        ),
      );

      final reportWrapper = AnimalSightingReportWrapper(sightingModel);

      // Act
      final json = reportWrapper.toJson();

      // Assert
      expect(json, isA<Map<String, dynamic>>());
      expect(
        json['description'],
        'Pack of wolves and foxes spotted near the forest',
      );
      expect(json['speciesID'], '1');
      expect(json['location']['latitude'], 52.0);
      expect(json['location']['longitude'], 4.0);
      expect(json['place']['latitude'], 52.1);
      expect(json['place']['longitude'], 4.1);
      expect(json['reportOfSighting']['involvedAnimals'], isA<List>());
      expect(json['moment'], contains('2023-01-01T14:30:00'));
    });

    test('should handle sighting with minimal required data', () {
      // Arrange
      final animalModel = AnimalModel(
        animalId: '1',
        animalName: 'Wolf',
        animalImagePath: 'assets/wolf.png',
        genderViewCounts: [],
      );

      final sightingModel = AnimalSightingModel(
        animals: [animalModel],
        animalSelected: animalModel,
        // No category
        description: '', // Empty description
        locations: [
          LocationModel(
            latitude: 52.0,
            longitude: 4.0,
            source: LocationSource.system,
          ),
          LocationModel(
            latitude: 52.1,
            longitude: 4.1,
            source: LocationSource.manual,
          ),
        ],
        dateTime: DateTimeModel(dateTime: DateTime(2023, 1, 1)),
        // No images
      );

      final reportWrapper = AnimalSightingReportWrapper(sightingModel);

      // Act
      final json = reportWrapper.toJson();

      // Assert
      expect(json, isA<Map<String, dynamic>>());
      expect(json['description'], '');
      expect(json['speciesID'], '1');
    });
  });
}
