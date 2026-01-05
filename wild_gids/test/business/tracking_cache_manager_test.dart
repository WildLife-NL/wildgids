import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:wildgids/managers/api_managers/tracking_cache_manager.dart';
import 'package:wildgids/models/beta_models/tracking_reading_model.dart';
import 'package:wildgids/interfaces/data_apis/tracking_api_interface.dart';
import 'package:wildgids/utils/connection_checker.dart';

/// Mock implementation of TrackingApiInterface for testing
class MockTrackingApi implements TrackingApiInterface {
  bool shouldFail = false;
  List<Map<String, dynamic>> sentReadings = [];

  @override
  Future<TrackingNotice?> addTrackingReading({
    required double lat,
    required double lon,
    required DateTime timestampUtc,
  }) async {
    if (shouldFail) {
      throw Exception('Network error');
    }

    sentReadings.add({'lat': lat, 'lon': lon, 'timestamp': timestampUtc});

    return null; // No notice for testing
  }

  @override
  Future<List<TrackingReadingResponse>> getMyTrackingReadings() async {
    if (shouldFail) {
      throw Exception('Network error');
    }
    return []; // Return empty list for testing
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TrackingCacheManager', () {
    late MockTrackingApi mockApi;
    late TrackingCacheManager cacheManager;
    bool mockHasInternet = true;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      mockApi = MockTrackingApi();
      cacheManager = TrackingCacheManager(trackingApi: mockApi);

      // Mock ConnectionChecker to control internet availability in tests
      ConnectionChecker.setHasInternetConnection =
          ([_]) async => mockHasInternet;
      mockHasInternet = true; // Default to having internet

      // Note: Not calling init() to avoid connectivity plugin issues in tests
    });

    tearDown(() async {
      // Reset ConnectionChecker to default implementation
      ConnectionChecker.setHasInternetConnection = ([amount]) async {
        try {
          final response = await http
              .get(Uri.parse('https://clients3.google.com/generate_204'))
              .timeout(Duration(seconds: amount ?? 3));
          return response.statusCode == 204;
        } catch (_) {
          return false;
        }
      };
      // Note: Not calling dispose() since we didn't call init()
    });

    test('should cache a tracking reading', () async {
      final reading = TrackingReading(
        latitude: 52.0,
        longitude: 5.0,
        timestampUtc: DateTime.utc(2025, 11, 20, 12, 0, 0),
      );

      await cacheManager.cacheReading(reading);

      final cached = await cacheManager.getCachedReadings();
      expect(cached.length, 1);
      expect(cached[0].latitude, 52.0);
      expect(cached[0].longitude, 5.0);
    });

    test('should send cached readings when connection is available', () async {
      // Cache some readings
      await cacheManager.cacheReading(
        TrackingReading(
          latitude: 52.0,
          longitude: 5.0,
          timestampUtc: DateTime.utc(2025, 11, 20, 12, 0, 0),
        ),
      );
      await cacheManager.cacheReading(
        TrackingReading(
          latitude: 52.1,
          longitude: 5.1,
          timestampUtc: DateTime.utc(2025, 11, 20, 12, 5, 0),
        ),
      );

      // Verify they are cached
      final cachedBefore = await cacheManager.getCachedReadings();
      expect(cachedBefore.length, 2);

      // Send cached readings
      await cacheManager.sendCachedReadings();

      // Verify they were sent
      expect(mockApi.sentReadings.length, 2);
      expect(mockApi.sentReadings[0]['lat'], 52.0);
      expect(mockApi.sentReadings[1]['lat'], 52.1);

      // Verify cache is cleared
      final cachedAfter = await cacheManager.getCachedReadings();
      expect(cachedAfter.length, 0);
    });

    test('should keep failed readings in cache', () async {
      // Cache some readings
      await cacheManager.cacheReading(
        TrackingReading(
          latitude: 52.0,
          longitude: 5.0,
          timestampUtc: DateTime.utc(2025, 11, 20, 12, 0, 0),
        ),
      );
      await cacheManager.cacheReading(
        TrackingReading(
          latitude: 52.1,
          longitude: 5.1,
          timestampUtc: DateTime.utc(2025, 11, 20, 12, 5, 0),
        ),
      );

      // Make API fail
      mockApi.shouldFail = true;

      // Try to send cached readings
      await cacheManager.sendCachedReadings();

      // Verify they are still cached
      final cachedAfter = await cacheManager.getCachedReadings();
      expect(cachedAfter.length, 2);
    });

    test(
      'should send reading immediately when connection is available',
      () async {
        mockApi.shouldFail = false;
        mockHasInternet = true;

        await cacheManager.sendOrCacheReading(
          lat: 52.0,
          lon: 5.0,
          timestampUtc: DateTime.utc(2025, 11, 20, 12, 0, 0),
        );

        // Should be sent immediately
        expect(mockApi.sentReadings.length, 1);

        // Should not be cached
        final cached = await cacheManager.getCachedReadings();
        expect(cached.length, 0);
      },
    );

    test('should cache reading when API fails', () async {
      mockApi.shouldFail = true;
      mockHasInternet = true;

      await cacheManager.sendOrCacheReading(
        lat: 52.0,
        lon: 5.0,
        timestampUtc: DateTime.utc(2025, 11, 20, 12, 0, 0),
      );

      // Should not be sent
      expect(mockApi.sentReadings.length, 0);

      // Should be cached
      final cached = await cacheManager.getCachedReadings();
      expect(cached.length, 1);
      expect(cached[0].latitude, 52.0);
    });

    test('should cache reading when no internet connection', () async {
      mockApi.shouldFail = false;
      mockHasInternet = false;

      await cacheManager.sendOrCacheReading(
        lat: 52.0,
        lon: 5.0,
        timestampUtc: DateTime.utc(2025, 11, 20, 12, 0, 0),
      );

      // Should not be sent
      expect(mockApi.sentReadings.length, 0);

      // Should be cached
      final cached = await cacheManager.getCachedReadings();
      expect(cached.length, 1);
      expect(cached[0].latitude, 52.0);
    });

    test('should handle multiple cached readings correctly', () async {
      final timestamps = [
        DateTime.utc(2025, 11, 20, 12, 0, 0),
        DateTime.utc(2025, 11, 20, 12, 5, 0),
        DateTime.utc(2025, 11, 20, 12, 10, 0),
      ];

      // Cache multiple readings
      for (int i = 0; i < 3; i++) {
        await cacheManager.cacheReading(
          TrackingReading(
            latitude: 52.0 + i * 0.1,
            longitude: 5.0 + i * 0.1,
            timestampUtc: timestamps[i],
          ),
        );
      }

      final cached = await cacheManager.getCachedReadings();
      expect(cached.length, 3);

      // Verify order is preserved
      for (int i = 0; i < 3; i++) {
        expect(cached[i].latitude, 52.0 + i * 0.1);
        expect(cached[i].longitude, 5.0 + i * 0.1);
        expect(cached[i].timestampUtc, timestamps[i]);
      }
    });
  });
}

