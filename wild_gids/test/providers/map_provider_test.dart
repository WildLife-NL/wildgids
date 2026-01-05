import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wildrapport/providers/map_provider.dart';

// Mock Position for testing
class MockPosition implements Position {
  final double lat;
  final double lng;
  final DateTime time;

  MockPosition({required this.lat, required this.lng, required this.time});

  @override
  double get latitude => lat;

  @override
  double get longitude => lng;

  @override
  DateTime get timestamp => time;

  @override
  double get accuracy => 0;

  @override
  double get altitude => 0;

  @override
  double get altitudeAccuracy => 0;

  @override
  double get heading => 0;

  @override
  double get headingAccuracy => 0;

  @override
  double get speed => 0;

  @override
  double get speedAccuracy => 0;

  @override
  bool get isMocked => true;

  @override
  int? get floor => null;

  @override
  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'timestamp': timestamp.toIso8601String(),
    'accuracy': accuracy,
    'altitude': altitude,
    'altitudeAccuracy': altitudeAccuracy,
    'heading': heading,
    'headingAccuracy': headingAccuracy,
    'speed': speed,
    'speedAccuracy': speedAccuracy,
    'floor': floor,
    'isMocked': isMocked,
  };
}

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
      final position = MockPosition(
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
      expect(mapProvider.selectedPosition, equals(position));
      expect(mapProvider.selectedAddress, equals(address));
      expect(mapProvider.isLoading, isFalse);
    });

    test(
      'should not update selected position if it is set to unknown',
      () async {
        // Arrange
        mapProvider.selectedAddress = '';
        final position = MockPosition(
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
      final position = MockPosition(
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
