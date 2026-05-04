import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:wildgids/interfaces/location/living_lab_interface.dart';
import 'package:wildgids/managers/map/living_lab_manager.dart';

void main() {
  late LivingLabInterface livingLabManager;

  setUp(() {
    livingLabManager = LivingLabManager();
  });

  group('LivingLabManager', () {
    test('should return all living labs', () {
      // Act
      final livingLabs = livingLabManager.getAllLivingLabs();

      // Assert
      expect(livingLabs, isNotEmpty);
      expect(livingLabs.length, 2); // Based on the implementation
      expect(livingLabs[0].id, 'np-zuid-kennemerland');
      expect(livingLabs[1].id, 'grenspark-kempenbroek');
    });

    test('should find living lab by id', () {
      // Act
      final zuidKennemerland = livingLabManager.getLivingLabById(
        'np-zuid-kennemerland',
      );
      final kempenBroek = livingLabManager.getLivingLabById(
        'grenspark-kempenbroek',
      );
      final nonExistent = livingLabManager.getLivingLabById('non-existent-id');

      // Assert
      expect(zuidKennemerland, isNotNull);
      expect(zuidKennemerland?.name, 'Nationaal Park Zuid-Kennemerland');
      expect(kempenBroek, isNotNull);
      expect(kempenBroek?.name, 'Grenspark Kempen~Broek');
      expect(nonExistent, isNull);
    });

    test('should find living lab by location', () {
      // Arrange
      final insideZuidKennemerland = LatLng(
        52.41,
        4.55,
      ); // Inside Zuid-Kennemerland
      final insideKempenBroek = LatLng(51.19, 5.72); // Inside Kempen~Broek
      final outsideAnyLab = LatLng(53.0, 6.0); // Outside any living lab

      // Act
      final labForZuidKennemerland = livingLabManager.getLivingLabByLocation(
        insideZuidKennemerland,
      );
      final labForKempenBroek = livingLabManager.getLivingLabByLocation(
        insideKempenBroek,
      );
      final labForOutside = livingLabManager.getLivingLabByLocation(
        outsideAnyLab,
      );

      // Assert
      expect(labForZuidKennemerland, isNotNull);
      expect(labForZuidKennemerland?.id, 'np-zuid-kennemerland');
      expect(labForKempenBroek, isNotNull);
      expect(labForKempenBroek?.id, 'grenspark-kempenbroek');
      expect(labForOutside, isNull);
    });

    test('should check if location is in any living lab', () {
      // Arrange
      final insideLab = LatLng(52.41, 4.55); // Inside Zuid-Kennemerland
      final outsideLab = LatLng(53.0, 6.0); // Outside any living lab

      // Act
      final isInsideAnyLab = livingLabManager.isLocationInAnyLivingLab(
        insideLab,
      );
      final isOutsideAnyLab = livingLabManager.isLocationInAnyLivingLab(
        outsideLab,
      );

      // Assert
      expect(isInsideAnyLab, true);
      expect(isOutsideAnyLab, false);
    });

    test('should correctly identify points on the boundary', () {
      // Arrange - Points exactly on the boundary of Zuid-Kennemerland
      final onBoundary = LatLng(52.4280, 4.5400); // First point in boundary

      // Act
      final isInLab = livingLabManager.isLocationInAnyLivingLab(onBoundary);

      // Assert - Points on boundary should be considered inside
      expect(isInLab, true);
    });

    test('should correctly identify edge cases', () {
      // Arrange - Edge cases near the boundaries
      // Using coordinates that are definitely inside the polygon
      final justInside = LatLng(52.41, 4.55); // Center of Zuid-Kennemerland
      final justOutside = LatLng(52.3850, 4.5050); // Outside Zuid-Kennemerland

      // Act
      final isJustInside = livingLabManager.isLocationInAnyLivingLab(
        justInside,
      );
      final isJustOutside = livingLabManager.isLocationInAnyLivingLab(
        justOutside,
      );

      // Assert
      expect(isJustInside, true);
      expect(isJustOutside, false);
    });
  });
}

