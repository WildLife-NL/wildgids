import 'package:flutter_test/flutter_test.dart';
import 'package:wildrapport/models/animal_waarneming_models/animal_sighting_model.dart';
import 'package:wildrapport/models/animal_waarneming_models/animal_model.dart';
import 'package:wildrapport/models/enums/animal_category.dart';
import 'package:wildrapport/models/beta_models/location_model.dart';
import 'package:wildrapport/models/enums/animal_condition.dart';
import 'package:wildrapport/models/enums/animal_gender.dart';
import 'package:wildrapport/models/ui_models/image_list_model.dart';
import 'package:wildrapport/models/ui_models/date_time_model.dart';
import 'package:wildrapport/models/enums/location_source.dart';

void main() {
  group('AnimalSightingModel', () {
    test('should have correct properties', () {
      // Arrange
      final animalModel = AnimalModel(
        animalId: '1',
        animalName: 'Wolf',
        animalImagePath: 'assets/wolf.png',
        genderViewCounts: [],
      );

      final sightingModel = AnimalSightingModel(
        animals: [],
        animalSelected: animalModel,
      );

      // Assert
      expect(sightingModel.animalSelected, animalModel);
      expect(sightingModel.animals, isEmpty);
      expect(sightingModel.category, null); // Category is null by default
    });

    test('should update category', () {
      // Arrange
      final animalModel = AnimalModel(
        animalId: '1',
        animalName: 'Wolf',
        animalImagePath: 'assets/wolf.png',
        genderViewCounts: [],
      );

      final sightingModel = AnimalSightingModel(
        animals: [],
        animalSelected: animalModel,
      );

      // Act
      final updatedModel = sightingModel.copyWith(
        category: AnimalCategory.roofdieren,
      );

      // Assert
      expect(updatedModel.category, AnimalCategory.roofdieren);
    });

    test('should update description', () {
      // Arrange
      final sightingModel = AnimalSightingModel(
        animals: [],
        description: 'Initial description',
      );

      // Act
      final updatedModel = sightingModel.copyWith(
        description: 'Updated description',
      );

      // Assert
      expect(updatedModel.description, 'Updated description');
    });

    test('should update locations', () {
      // Arrange
      final sightingModel = AnimalSightingModel(animals: [], locations: []);

      final newLocations = [
        LocationModel(
          latitude: 52.3676,
          longitude: 4.9041,
          source: LocationSource.system,
        ),
      ];

      // Act
      final updatedModel = sightingModel.copyWith(locations: newLocations);

      // Assert
      expect(updatedModel.locations, newLocations);
    });

    test('should update dateTime', () {
      // Arrange
      final sightingModel = AnimalSightingModel(animals: []);

      final dateTime = DateTimeModel(dateTime: DateTime.now());

      // Act
      final updatedModel = sightingModel.copyWith(dateTime: dateTime);

      // Assert
      expect(updatedModel.dateTime, dateTime);
    });

    test('should update images', () {
      // Arrange
      final sightingModel = AnimalSightingModel(animals: []);

      final images = ImageListModel(
        imagePaths: ['path/to/image1.jpg', 'path/to/image2.jpg'],
      );

      // Act
      final updatedModel = sightingModel.copyWith(images: images);

      // Assert
      expect(updatedModel.images, images);
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
      );

      // Act
      final json = sightingModel.toJson();

      // Assert
      expect(json, isA<Map<String, dynamic>>());
      expect(json['category'], AnimalCategory.roofdieren.toString());
      expect(json['description'], 'Test description');
      expect(json['animals'], isA<List>());
      expect(json['animals']?.length, 1);
      expect(json['animals']?[0]['animalId'], '1');
      expect(json['animals']?[0]['animalName'], 'Wolf');
    });

    test('should create from JSON correctly', () {
      // Arrange
      final Map<String, dynamic> json = {
        'animals': [
          {
            'animalId': '1',
            'animalName': 'Wolf',
            'animalImagePath': 'assets/wolf.png',
            'genderViewCounts': [],
          },
        ],
        'category': 'AnimalCategory.roofdieren',
        'description': 'Test description',
      };

      // Act
      final sightingModel = AnimalSightingModel.fromJson(json);

      // Assert
      expect(sightingModel.animals?.length, 1);
      expect(sightingModel.animals?[0].animalId, '1');
      expect(sightingModel.animals?[0].animalName, 'Wolf');
      expect(sightingModel.category, AnimalCategory.roofdieren);
      expect(sightingModel.description, 'Test description');
    });

    test('should add animal to list', () {
      // Arrange
      final animalModel = AnimalModel(
        animalId: '1',
        animalName: 'Wolf',
        animalImagePath: 'assets/wolf.png',
        genderViewCounts: [],
      );

      final sightingModel = AnimalSightingModel(
        animals: [],
        animalSelected: animalModel,
      );

      final newAnimal = AnimalModel(
        animalId: '2',
        animalName: 'Fox',
        animalImagePath: 'assets/fox.png',
        genderViewCounts: [],
      );

      // Act
      sightingModel.animals?.add(newAnimal);

      // Assert
      expect(sightingModel.animals?.length, 1);
      expect(sightingModel.animals?[0].animalId, '2');
      expect(sightingModel.animals?[0].animalName, 'Fox');
    });

    test('should update location correctly', () {
      // Arrange
      final sightingModel = AnimalSightingModel(
        animals: [],
        animalSelected: null,
      );

      final location = LocationModel(
        latitude: 52.3676,
        longitude: 4.9041,
        source: LocationSource.system,
      );

      // Act
      final updatedModel = sightingModel.copyWith(locations: [location]);

      // Assert
      expect(updatedModel.locations?.first, location);
      expect(updatedModel.locations?.first.latitude, 52.3676);
      expect(updatedModel.locations?.first.longitude, 4.9041);
      expect(updatedModel.locations?.first.source, LocationSource.system);
    });

    test('should update dateTime correctly', () {
      // Arrange
      final sightingModel = AnimalSightingModel(
        animals: [],
        animalSelected: null,
      );

      final dateTime = DateTimeModel(dateTime: DateTime(2023, 5, 15, 14, 30));

      // Act
      final updatedModel = sightingModel.copyWith(dateTime: dateTime);

      // Assert
      expect(updatedModel.dateTime, dateTime);
      expect(updatedModel.dateTime?.dateTime?.year, 2023);
      expect(updatedModel.dateTime?.dateTime?.month, 5);
      expect(updatedModel.dateTime?.dateTime?.day, 15);
      expect(updatedModel.dateTime?.dateTime?.hour, 14);
      expect(updatedModel.dateTime?.dateTime?.minute, 30);
    });

    test('should update images correctly', () {
      // Arrange
      final sightingModel = AnimalSightingModel(
        animals: [],
        animalSelected: null,
      );

      final images = ImageListModel(imagePaths: ['image1.jpg', 'image2.jpg']);

      // Act
      final updatedModel = sightingModel.copyWith(images: images);

      // Assert
      expect(updatedModel.images, images);
      expect(updatedModel.images?.imagePaths.length, 2);
      expect(updatedModel.images?.imagePaths[0], 'image1.jpg');
      expect(updatedModel.images?.imagePaths[1], 'image2.jpg');
    });

    test('should handle null values in toJson', () {
      // Arrange
      final sightingModel = AnimalSightingModel(
        animals: null,
        animalSelected: null,
      );

      // Act
      final json = sightingModel.toJson();

      // Assert
      expect(json, isA<Map<String, dynamic>>());
      expect(json['animals'], isNull);
      expect(json['category'], isNull);
      expect(json['description'], isNull);
      expect(json['locations'], isNull);
      expect(json['dateTime'], isNull);
      expect(json['images'], isNull);
    });

    test('should handle empty list in toJson', () {
      // Arrange
      final sightingModel = AnimalSightingModel(
        animals: [],
        animalSelected: null,
      );

      // Act
      final json = sightingModel.toJson();

      // Assert
      expect(json, isA<Map<String, dynamic>>());
      expect(json['animals'], isEmpty);
    });

    test('should create a copy with updated values using copyWith', () {
      // Arrange
      final originalModel = AnimalSightingModel(
        animals: [],
        category: AnimalCategory.roofdieren,
        description: 'Original description',
      );

      final newAnimal = AnimalModel(
        animalId: '2',
        animalName: 'Fox',
        animalImagePath: 'assets/fox.png',
        genderViewCounts: [],
      );

      // Act
      final copiedModel = originalModel.copyWith(
        animals: [newAnimal],
        category: AnimalCategory.evenhoevigen,
        description: 'Updated description',
      );

      // Assert
      expect(copiedModel.animals?.length, 1);
      expect(copiedModel.animals?[0].animalId, '2');
      expect(copiedModel.category, AnimalCategory.evenhoevigen);
      expect(copiedModel.description, 'Updated description');

      // Original should remain unchanged
      expect(originalModel.animals?.length, 0);
      expect(originalModel.category, AnimalCategory.roofdieren);
      expect(originalModel.description, 'Original description');
    });

    test('copyWith should keep original values when parameters are null', () {
      // Arrange
      final animal = AnimalModel(
        animalId: '1',
        animalName: 'Wolf',
        animalImagePath: 'assets/wolf.png',
        genderViewCounts: [],
      );

      final originalModel = AnimalSightingModel(
        animals: [animal],
        animalSelected: animal,
        category: AnimalCategory.roofdieren,
        description: 'Test description',
        locations: [
          LocationModel(
            latitude: 52.0,
            longitude: 4.0,
            source: LocationSource.system,
          ),
        ],
        dateTime: DateTimeModel(dateTime: DateTime.now()),
        images: ImageListModel(imagePaths: []),
      );

      // Act
      final copiedModel = originalModel.copyWith();

      // Assert
      expect(copiedModel.animals, originalModel.animals);
      expect(copiedModel.animalSelected, originalModel.animalSelected);
      expect(copiedModel.category, originalModel.category);
      expect(copiedModel.description, originalModel.description);
      expect(copiedModel.locations, originalModel.locations);
      expect(copiedModel.dateTime, originalModel.dateTime);
      expect(copiedModel.images, originalModel.images);
    });

    test('fromJson should handle null values correctly', () {
      // Arrange
      final Map<String, dynamic> json = {
        'animals': null,
        'animalSelected': null,
        'category': null,
        'description': null,
        'locations': null,
        'dateTime': null,
        'images': null,
      };

      // Act
      final model = AnimalSightingModel.fromJson(json);

      // Assert
      expect(model.animals, null);
      expect(model.animalSelected, null);
      expect(model.category, null);
      expect(model.description, null);
      expect(model.locations, null);
      expect(model.dateTime, null);
      expect(model.images, null);
    });

    test('fromJson should handle complex nested objects', () {
      // Arrange
      final Map<String, dynamic> json = {
        'animals': [
          {
            'animalId': '1',
            'animalName': 'Wolf',
            'animalImagePath': 'assets/wolf.png',
            'condition': 'AnimalCondition.levend',
            'genderViewCounts': [
              {
                'gender': 'AnimalGender.mannelijk',
                'viewCount': {
                  'pasGeborenAmount': 1,
                  'onvolwassenAmount': 2,
                  'volwassenAmount': 3,
                  'unknownAmount': 0,
                },
              },
            ],
          },
        ],
        'animalSelected': {
          'animalId': '2',
          'animalName': 'Fox',
          'animalImagePath': 'assets/fox.png',
          'condition': 'AnimalCondition.dood',
          'genderViewCounts': [
            {
              'gender': 'AnimalGender.vrouwelijk',
              'viewCount': {
                'pasGeborenAmount': 0,
                'onvolwassenAmount': 1,
                'volwassenAmount': 2,
                'unknownAmount': 0,
              },
            },
          ],
        },
        'category': 'AnimalCategory.roofdieren',
        'description': 'Test description',
        'locations': [
          {
            'latitude': 52.0,
            'longitude': 4.0,
            'source': 'LocationSource.system',
          },
        ],
        'dateTime': {'dateTime': '2023-01-01T12:00:00.000Z'},
        'images': {
          'imagePaths': ['image1.jpg', 'image2.jpg'],
        },
      };

      // Act
      final model = AnimalSightingModel.fromJson(json);

      // Assert
      expect(model.animals?.length, 1);
      expect(model.animals?[0].animalId, '1');
      expect(model.animals?[0].animalName, 'Wolf');
      expect(model.animals?[0].condition, AnimalCondition.levend);
      expect(model.animals?[0].genderViewCounts.length, 1);
      expect(
        model.animals?[0].genderViewCounts[0].gender,
        AnimalGender.mannelijk,
      );
      expect(
        model.animals?[0].genderViewCounts[0].viewCount.pasGeborenAmount,
        1,
      );

      expect(model.animalSelected?.animalId, '2');
      expect(model.animalSelected?.animalName, 'Fox');
      expect(model.animalSelected?.condition, AnimalCondition.dood);
      expect(model.animalSelected?.genderViewCounts.length, 1);
      expect(
        model.animalSelected?.genderViewCounts[0].gender,
        AnimalGender.vrouwelijk,
      );

      expect(model.category, AnimalCategory.roofdieren);
      expect(model.description, 'Test description');
      expect(model.locations?.length, 1);
      expect(model.locations?[0].latitude, 52.0);
      expect(model.locations?[0].longitude, 4.0);
      expect(model.locations?[0].source, LocationSource.system);
      expect(model.dateTime, isNotNull);
      expect(model.images, isNotNull);
      expect(model.images?.imagePaths.length, 2);
      expect(model.images?.imagePaths[0], 'image1.jpg');
      expect(model.images?.imagePaths[1], 'image2.jpg');
    });

    test('toJson should handle null values correctly', () {
      // Arrange
      final model = AnimalSightingModel();

      // Act
      final json = model.toJson();

      // Assert
      expect(json['animals'], null);
      expect(json['category'], null);
      expect(json['description'], null);
      expect(json['locations'], null);
      expect(json['dateTime'], null);
      expect(json['images'], null);
    });
  });
}
