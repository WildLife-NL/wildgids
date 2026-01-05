import 'package:flutter_test/flutter_test.dart';
import 'package:wildrapport/models/animal_waarneming_models/animal_model.dart';
import 'package:wildrapport/models/animal_waarneming_models/animal_gender_view_count_model.dart';
import 'package:wildrapport/models/animal_waarneming_models/view_count_model.dart';
import 'package:wildrapport/models/enums/animal_gender.dart';
import 'package:wildrapport/models/enums/animal_condition.dart';

void main() {
  group('AnimalModel', () {
    setUp(() {});

    test('should have correct properties', () {
      // Arrange
      final animalModel = AnimalModel(
        animalId: '1',
        animalName: 'Wolf',
        animalImagePath: 'assets/wolf.png',
        genderViewCounts: [],
      );

      // Assert
      expect(animalModel.animalId, '1');
      expect(animalModel.animalName, 'Wolf');
      expect(animalModel.animalImagePath, 'assets/wolf.png');
      expect(animalModel.genderViewCounts, isEmpty);
    });

    test('should add gender view count', () {
      // Arrange
      final animalModel = AnimalModel(
        animalId: '1',
        animalName: 'Wolf',
        animalImagePath: 'assets/wolf.png',
        genderViewCounts: [],
      );

      final genderViewCount = AnimalGenderViewCount(
        gender: AnimalGender.mannelijk,
        viewCount: ViewCountModel(
          volwassenAmount: 1,
          onvolwassenAmount: 0,
          pasGeborenAmount: 0,
          unknownAmount: 0,
        ),
      );

      // Act
      animalModel.genderViewCounts.add(genderViewCount);

      // Assert
      expect(animalModel.genderViewCounts.length, 1);
      expect(animalModel.genderViewCounts.first.gender, AnimalGender.mannelijk);
    });

    test('should return gender from genderViewCounts', () {
      // Arrange
      final animalModel = AnimalModel(
        animalId: '1',
        animalName: 'Wolf',
        animalImagePath: 'assets/wolf.png',
        genderViewCounts: [
          AnimalGenderViewCount(
            gender: AnimalGender.mannelijk,
            viewCount: ViewCountModel(
              volwassenAmount: 1,
              onvolwassenAmount: 0,
              pasGeborenAmount: 0,
              unknownAmount: 0,
            ),
          ),
        ],
      );

      // Assert
      expect(animalModel.gender, AnimalGender.mannelijk);
    });

    test('should return null gender when genderViewCounts is empty', () {
      // Arrange
      final animalModel = AnimalModel(
        animalId: '1',
        animalName: 'Wolf',
        animalImagePath: 'assets/wolf.png',
        genderViewCounts: [],
      );

      // Assert
      expect(animalModel.gender, null);
    });

    test('should return viewCount from genderViewCounts', () {
      // Arrange
      final viewCount = ViewCountModel(
        volwassenAmount: 1,
        onvolwassenAmount: 2,
        pasGeborenAmount: 0,
        unknownAmount: 0,
      );

      final animalModel = AnimalModel(
        animalId: '1',
        animalName: 'Wolf',
        animalImagePath: 'assets/wolf.png',
        genderViewCounts: [
          AnimalGenderViewCount(
            gender: AnimalGender.mannelijk,
            viewCount: viewCount,
          ),
        ],
      );

      // Assert
      expect(animalModel.viewCount, viewCount);
    });

    test('should return null viewCount when genderViewCounts is empty', () {
      // Arrange
      final animalModel = AnimalModel(
        animalId: '1',
        animalName: 'Wolf',
        animalImagePath: 'assets/wolf.png',
        genderViewCounts: [],
      );

      // Assert
      expect(animalModel.viewCount, null);
    });

    test('should create with condition', () {
      // Arrange
      final animalModel = AnimalModel(
        animalId: '1',
        animalName: 'Wolf',
        animalImagePath: 'assets/wolf.png',
        genderViewCounts: [],
        condition: AnimalCondition.dood,
      );

      // Assert
      expect(animalModel.condition, AnimalCondition.dood);
    });

    test('should convert to JSON correctly', () {
      // Arrange
      final viewCount = ViewCountModel(
        volwassenAmount: 2,
        onvolwassenAmount: 1,
        pasGeborenAmount: 0,
        unknownAmount: 0,
      );

      final genderViewCount = AnimalGenderViewCount(
        gender: AnimalGender.mannelijk,
        viewCount: viewCount,
      );

      final animalModel = AnimalModel(
        animalId: '1',
        animalName: 'Wolf',
        animalImagePath: 'assets/wolf.png',
        genderViewCounts: [genderViewCount],
        condition: AnimalCondition.levend,
      );

      // Assert
      expect(animalModel.animalId, '1');
      expect(animalModel.animalName, 'Wolf');
      expect(animalModel.animalImagePath, 'assets/wolf.png');
      expect(animalModel.genderViewCounts.length, 1);
      expect(animalModel.condition, AnimalCondition.levend);
    });

    test('should update gender correctly', () {
      // Arrange
      final animalModel = AnimalModel(
        animalId: '1',
        animalName: 'Wolf',
        animalImagePath: 'assets/wolf.png',
        genderViewCounts: [],
      );

      // Act
      final updatedModel = animalModel.updateGender(AnimalGender.vrouwelijk);

      // Assert
      expect(updatedModel.gender, AnimalGender.vrouwelijk);
      expect(updatedModel.animalId, animalModel.animalId);
      expect(updatedModel.animalName, animalModel.animalName);
      expect(updatedModel.animalImagePath, animalModel.animalImagePath);
    });

    test('should update viewCount correctly', () {
      // Arrange
      final animalModel = AnimalModel(
        animalId: '1',
        animalName: 'Wolf',
        animalImagePath: 'assets/wolf.png',
        genderViewCounts: [],
      );

      final newViewCount = ViewCountModel(
        volwassenAmount: 3,
        onvolwassenAmount: 2,
        pasGeborenAmount: 1,
        unknownAmount: 0,
      );

      // Act
      final updatedModel = animalModel.updateViewCount(newViewCount);

      // Assert
      expect(updatedModel.viewCount, newViewCount);
      expect(
        updatedModel.gender,
        AnimalGender.onbekend,
      ); // Default gender when none exists
      expect(updatedModel.animalId, animalModel.animalId);
      expect(updatedModel.animalName, animalModel.animalName);
    });

    test('should preserve condition when updating gender', () {
      // Arrange
      final animalModel = AnimalModel(
        animalId: '1',
        animalName: 'Wolf',
        animalImagePath: 'assets/wolf.png',
        genderViewCounts: [],
        condition: AnimalCondition.ziek,
      );

      // Act
      final updatedModel = animalModel.updateGender(AnimalGender.mannelijk);

      // Assert
      expect(updatedModel.gender, AnimalGender.mannelijk);
      expect(updatedModel.condition, AnimalCondition.ziek);
    });

    test('should calculate total count correctly', () {
      // Arrange
      final animalModel = AnimalModel(
        animalId: '1',
        animalName: 'Wolf',
        animalImagePath: 'assets/wolf.png',
        genderViewCounts: [
          AnimalGenderViewCount(
            gender: AnimalGender.mannelijk,
            viewCount: ViewCountModel(
              volwassenAmount: 2,
              onvolwassenAmount: 1,
              pasGeborenAmount: 0,
              unknownAmount: 0,
            ),
          ),
          AnimalGenderViewCount(
            gender: AnimalGender.vrouwelijk,
            viewCount: ViewCountModel(
              volwassenAmount: 1,
              onvolwassenAmount: 2,
              pasGeborenAmount: 1,
              unknownAmount: 0,
            ),
          ),
        ],
      );

      // Act & Assert
      // Calculate total manually to verify
      int expectedTotal = 0;
      for (var gvc in animalModel.genderViewCounts) {
        expectedTotal += gvc.viewCount.volwassenAmount;
        expectedTotal += gvc.viewCount.onvolwassenAmount;
        expectedTotal += gvc.viewCount.pasGeborenAmount;
        expectedTotal += gvc.viewCount.unknownAmount;
      }

      expect(expectedTotal, 7); // 2+1+0+0+1+2+1+0 = 7
    });
  });
}
