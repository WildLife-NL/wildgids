import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wildgids/providers/map_provider.dart';

Position mockPosition({
  required double lat,
  required double lng,
  required DateTime time,
}) => Position(
  latitude: lat,
  longitude: lng,
  timestamp: time,
  accuracy: 0,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
  isMocked: true,
);

void main() {
  late MapProvider mapProvider;

  setUp(() {
    mapProvider = MapProvider();
  });

  group('MapProvider', () {
    test('should initialize with default values', () {
      expect(mapProvider.selectedPosition, isNull);
      expect(mapProvider.selectedAddress, '');
      expect(mapProvider.currentPosition, isNull);
      expect(mapProvider.currentAddress, '');
      expect(mapProvider.isLoading, isFalse);
      expect(mapProvider.isInitialized, isFalse);
    });

    test(
      'should create map controller when accessed before initialization',
      () {
        // Act
        final controller = mapProvider.mapController;

        // Assert
        expect(controller, isA<MapController>());
        // Note: Accessing the controller now sets isInitialized to true
        expect(mapProvider.isInitialized, isTrue);
      },
    );

    test('should initialize map controller explicitly', () async {
      // Act
      await mapProvider.initialize();

      // Assert
      expect(mapProvider.isInitialized, isTrue);
      expect(mapProvider.mapController, isA<MapController>());
      expect(mapProvider.isLoading, isFalse);
    });

    test('should not reinitialize if already initialized', () async {
      // Arrange
      await mapProvider.initialize();
      final initialController = mapProvider.mapController;

      // Act
      await mapProvider.initialize();

      // Assert
      expect(mapProvider.mapController, equals(initialController));
    });

    test('should update position and address', () async {
      // Arrange
      final position = mockPosition(
        lat: 52.3676,
        lng: 4.9041,
        time: DateTime.now(),
      );
      const address = 'Amsterdam, Netherlands';
      // selectedAddress must be non-empty for updatePosition to mirror current values.
      mapProvider.selectedAddress = 'previous';

      // Act
      await mapProvider.updatePosition(position, address);

      // Assert
      expect(mapProvider.currentPosition, equals(position));
      expect(mapProvider.currentAddress, equals(address));
      expect(mapProvider.selectedPosition, equals(position));
      expect(mapProvider.selectedAddress, equals(address));
      expect(mapProvider.isLoading, isFalse);
    });

    test(
      'should not update selected position if it is set to unknown',
      () async {
        // Arrange
        mapProvider.selectedAddress = '';
        final position = mockPosition(
          lat: 52.3676,
          lng: 4.9041,
          time: DateTime.now(),
        );
        const address = 'Amsterdam, Netherlands';

        // Act
        await mapProvider.updatePosition(position, address);

        // Assert
        expect(mapProvider.currentPosition, equals(position));
        expect(mapProvider.currentAddress, equals(address));
        expect(mapProvider.selectedPosition, isNot(equals(position)));
        expect(mapProvider.selectedAddress, equals(''));
      },
    );

    test('should set selected location', () {
      // Arrange
      final position = mockPosition(
        lat: 52.3676,
        lng: 4.9041,
        time: DateTime.now(),
      );
      const address = 'Amsterdam, Netherlands';

      // Act
      mapProvider.setSelectedLocation(position, address);

      // Assert
      expect(mapProvider.selectedPosition, equals(position));
      expect(mapProvider.selectedAddress, equals(address));
    });

    test('should set loading state', () {
      // Act
      mapProvider.setLoading(true);

      // Assert
      expect(mapProvider.isLoading, isTrue);

      // Act again
      mapProvider.setLoading(false);

      // Assert again
      expect(mapProvider.isLoading, isFalse);
    });

    test('should handle dispose correctly', () {
      // Arrange
      mapProvider.initialize();

      // Act
      mapProvider.dispose();

      // Assert - no exceptions should be thrown
      expect(true, isTrue);
    });
  });
}
