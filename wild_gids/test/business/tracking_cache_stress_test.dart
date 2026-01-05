import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildrapport/managers/api_managers/tracking_cache_manager.dart';
import 'package:wildrapport/models/beta_models/tracking_reading_model.dart';
import 'package:wildrapport/interfaces/data_apis/tracking_api_interface.dart';
import 'dart:convert';

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

    return null;
  }

  @override
  Future<List<TrackingReadingResponse>> getMyTrackingReadings() async {
    if (shouldFail) {
      throw Exception('Network error');
    }
    return [];
  }
}


void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TrackingCacheManager - Storage Stress Tests', () {
    late MockTrackingApi mockApi;
    late TrackingCacheManager cacheManager;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      mockApi = MockTrackingApi();
      cacheManager = TrackingCacheManager(trackingApi: mockApi);
    });

    test('should handle 100 cached readings', () async {
      print('\n=== Testing 100 readings ===');
      final startTime = DateTime.now();

      // Cache 100 readings
      for (int i = 0; i < 100; i++) {
        await cacheManager.cacheReading(
          TrackingReading(
            latitude: 52.0 + (i * 0.0001),
            longitude: 5.0 + (i * 0.0001),
            timestampUtc: DateTime.utc(2025, 11, 26, 12, 0, i),
          ),
        );
      }

      final cacheTime = DateTime.now().difference(startTime);
      print('Time to cache 100 readings: ${cacheTime.inMilliseconds}ms');

      // Calculate storage size
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getStringList('cached_tracking_readings');
      final storageSize = cachedJson!.join('').length;
      print(
        'Storage size: ${storageSize} bytes (${(storageSize / 1024).toStringAsFixed(2)} KB)',
      );

      // Verify all readings cached
      final cached = await cacheManager.getCachedReadings();
      expect(cached.length, 100);
      print('✓ All 100 readings cached successfully\n');
    });

    test('should handle 1,000 cached readings', () async {
      print('\n=== Testing 1,000 readings ===');
      final startTime = DateTime.now();

      // Cache 1,000 readings
      for (int i = 0; i < 1000; i++) {
        await cacheManager.cacheReading(
          TrackingReading(
            latitude: 52.0 + (i * 0.0001),
            longitude: 5.0 + (i * 0.0001),
            timestampUtc: DateTime.utc(2025, 11, 26, 12, 0, i % 60),
          ),
        );
      }

      final cacheTime = DateTime.now().difference(startTime);
      print('Time to cache 1,000 readings: ${cacheTime.inMilliseconds}ms');

      // Calculate storage size
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getStringList('cached_tracking_readings');
      final storageSize = cachedJson!.join('').length;
      print(
        'Storage size: ${storageSize} bytes (${(storageSize / 1024).toStringAsFixed(2)} KB)',
      );
      print(
        'Average size per reading: ${(storageSize / 1000).toStringAsFixed(2)} bytes',
      );

      // Verify all readings cached
      final cached = await cacheManager.getCachedReadings();
      expect(cached.length, 1000);
      print('✓ All 1,000 readings cached successfully\n');
    });

    test('should handle 10,000 cached readings', () async {
      print('\n=== Testing 10,000 readings ===');
      final startTime = DateTime.now();

      // Cache 10,000 readings
      for (int i = 0; i < 10000; i++) {
        await cacheManager.cacheReading(
          TrackingReading(
            latitude: 52.0 + (i * 0.0001),
            longitude: 5.0 + (i * 0.0001),
            timestampUtc: DateTime.utc(
              2025,
              11,
              26,
              12 + (i ~/ 3600),
              (i % 3600) ~/ 60,
              i % 60,
            ),
          ),
        );
      }

      final cacheTime = DateTime.now().difference(startTime);
      print(
        'Time to cache 10,000 readings: ${cacheTime.inMilliseconds}ms (${(cacheTime.inMilliseconds / 1000).toStringAsFixed(2)}s)',
      );

      // Calculate storage size
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getStringList('cached_tracking_readings');
      final storageSize = cachedJson!.join('').length;
      print(
        'Storage size: ${storageSize} bytes (${(storageSize / 1024).toStringAsFixed(2)} KB or ${(storageSize / (1024 * 1024)).toStringAsFixed(2)} MB)',
      );
      print(
        'Average size per reading: ${(storageSize / 10000).toStringAsFixed(2)} bytes',
      );

      // Verify all readings cached
      final cached = await cacheManager.getCachedReadings();
      expect(cached.length, 10000);
      print('✓ All 10,000 readings cached successfully\n');
    });

    test('should calculate storage for 100,000 readings (estimate)', () async {
      print('\n=== Estimating 100,000 readings ===');

      // Cache a sample to calculate average size
      for (int i = 0; i < 100; i++) {
        await cacheManager.cacheReading(
          TrackingReading(
            latitude: 52.0 + (i * 0.0001),
            longitude: 5.0 + (i * 0.0001),
            timestampUtc: DateTime.utc(2025, 11, 26, 12, 0, i),
          ),
        );
      }

      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getStringList('cached_tracking_readings');
      final sampleSize = cachedJson!.join('').length;
      final avgPerReading = sampleSize / 100;

      print('Sample size (100 readings): ${sampleSize} bytes');
      print('Average per reading: ${avgPerReading.toStringAsFixed(2)} bytes');

      final estimate100k = avgPerReading * 100000;
      print('\nEstimated storage for 100,000 readings:');
      print('  - ${estimate100k.toStringAsFixed(0)} bytes');
      print('  - ${(estimate100k / 1024).toStringAsFixed(2)} KB');
      print('  - ${(estimate100k / (1024 * 1024)).toStringAsFixed(2)} MB');

      final estimate1m = avgPerReading * 1000000;
      print('\nEstimated storage for 1,000,000 readings:');
      print('  - ${estimate1m.toStringAsFixed(0)} bytes');
      print('  - ${(estimate1m / 1024).toStringAsFixed(2)} KB');
      print('  - ${(estimate1m / (1024 * 1024)).toStringAsFixed(2)} MB');

      print('\n');
    });

    test('should measure retrieval performance for large cache', () async {
      print('\n=== Testing retrieval performance ===');

      // Cache 5,000 readings
      for (int i = 0; i < 5000; i++) {
        await cacheManager.cacheReading(
          TrackingReading(
            latitude: 52.0 + (i * 0.0001),
            longitude: 5.0 + (i * 0.0001),
            timestampUtc: DateTime.utc(2025, 11, 26, 12, 0, i % 60),
          ),
        );
      }

      // Measure retrieval time
      final retrievalStart = DateTime.now();
      final cached = await cacheManager.getCachedReadings();
      final retrievalTime = DateTime.now().difference(retrievalStart);

      print('Cached readings: ${cached.length}');
      print('Retrieval time: ${retrievalTime.inMilliseconds}ms');
      print(
        'Average retrieval time per reading: ${(retrievalTime.inMilliseconds / cached.length).toStringAsFixed(4)}ms',
      );

      expect(cached.length, 5000);
      print('✓ Retrieval successful\n');
    });

    test('should analyze JSON structure size', () async {
      print('\n=== Analyzing JSON structure ===');

      final reading = TrackingReading(
        latitude: 52.123456789,
        longitude: 5.987654321,
        timestampUtc: DateTime.utc(2025, 11, 26, 12, 30, 45, 123, 456),
      );

      final json = reading.toJson();
      final jsonString = jsonEncode(json);

      print('Sample reading JSON: $jsonString');
      print('JSON size: ${jsonString.length} bytes');
      print('Components:');
      print('  - latitude: ${json['latitude']}');
      print('  - longitude: ${json['longitude']}');
      print('  - timestampUtc: ${json['timestampUtc']}');
      print('\n');
    });

    test(
      'should test realistic scenario: 1 week offline at 10s intervals',
      () async {
        print('\n=== Realistic Scenario: 1 week offline ===');
        print('Tracking interval: 10 seconds');

        // 1 week = 7 days * 24 hours * 60 minutes * 6 readings per minute
        final readingsPerWeek = 7 * 24 * 60 * 6;
        print('Expected readings in 1 week: $readingsPerWeek');

        final startTime = DateTime.now();

        // Cache readings for 1 week
        for (int i = 0; i < readingsPerWeek; i++) {
          await cacheManager.cacheReading(
            TrackingReading(
              latitude: 52.0 + (i * 0.00001),
              longitude: 5.0 + (i * 0.00001),
              timestampUtc: DateTime.utc(
                2025,
                11,
                26,
              ).add(Duration(seconds: i * 10)),
            ),
          );
        }

        final cacheTime = DateTime.now().difference(startTime);
        print(
          'Time to cache: ${(cacheTime.inMilliseconds / 1000).toStringAsFixed(2)}s',
        );

        // Calculate storage
        final prefs = await SharedPreferences.getInstance();
        final cachedJson = prefs.getStringList('cached_tracking_readings');
        final storageSize = cachedJson!.join('').length;

        print(
          'Storage used: ${(storageSize / (1024 * 1024)).toStringAsFixed(2)} MB',
        );
        print(
          'Average per reading: ${(storageSize / readingsPerWeek).toStringAsFixed(2)} bytes',
        );

        final cached = await cacheManager.getCachedReadings();
        expect(cached.length, readingsPerWeek);
        print('✓ Successfully cached $readingsPerWeek readings\n');
      },
    );

    test('should test edge case: maximum SharedPreferences capacity', () async {
      print('\n=== Testing SharedPreferences limits ===');
      print(
        'Note: SharedPreferences on Android has a practical limit of ~1-2 MB per key',
      );
      print(
        '      On iOS, the limit is higher but still constrained by device storage\n',
      );

      int readingsCount = 0;
      bool limitReached = false;

      try {
        // Keep adding readings until we hit a limit or reach a reasonable test size
        for (int i = 0; i < 15000; i++) {
          await cacheManager.cacheReading(
            TrackingReading(
              latitude: 52.0 + (i * 0.0001),
              longitude: 5.0 + (i * 0.0001),
              timestampUtc: DateTime.utc(
                2025,
                11,
                26,
                12 + (i ~/ 3600),
                (i % 3600) ~/ 60,
                i % 60,
              ),
            ),
          );
          readingsCount++;

          // Check storage size every 1000 readings
          if (i > 0 && i % 1000 == 0) {
            final prefs = await SharedPreferences.getInstance();
            final cachedJson = prefs.getStringList('cached_tracking_readings');
            final storageSize = cachedJson!.join('').length;
            print(
              '${i} readings: ${(storageSize / (1024 * 1024)).toStringAsFixed(2)} MB',
            );
          }
        }
      } catch (e) {
        print('⚠ Limit reached at $readingsCount readings');
        print('Error: $e');
        limitReached = true;
      }

      if (!limitReached) {
        final prefs = await SharedPreferences.getInstance();
        final cachedJson = prefs.getStringList('cached_tracking_readings');
        final storageSize = cachedJson!.join('').length;
        print('Successfully cached $readingsCount readings');
        print(
          'Total storage: ${(storageSize / (1024 * 1024)).toStringAsFixed(2)} MB',
        );
      }

      print('\n');
    });

    test('should provide storage recommendations', () {
      print('\n=== Storage Recommendations ===\n');

      // Based on ~120 bytes per reading (typical)
      const avgBytesPerReading = 120;

      print('Tracking interval: 10 seconds (6 readings/minute)');
      print('Average reading size: $avgBytesPerReading bytes\n');

      final scenarios = [
        {'duration': '1 hour', 'readings': 6 * 60, 'name': '1 hour offline'},
        {
          'duration': '6 hours',
          'readings': 6 * 60 * 6,
          'name': '6 hours offline',
        },
        {'duration': '1 day', 'readings': 6 * 60 * 24, 'name': '1 day offline'},
        {
          'duration': '3 days',
          'readings': 6 * 60 * 24 * 3,
          'name': '3 days offline',
        },
        {
          'duration': '1 week',
          'readings': 6 * 60 * 24 * 7,
          'name': '1 week offline',
        },
        {
          'duration': '1 month',
          'readings': 6 * 60 * 24 * 30,
          'name': '1 month offline',
        },
      ];

      for (var scenario in scenarios) {
        final readings = scenario['readings'] as int;
        final storageBytes = readings * avgBytesPerReading;
        final storageMB = storageBytes / (1024 * 1024);

        print('${scenario['name']}:');
        print('  Readings: $readings');
        print('  Storage: ${storageMB.toStringAsFixed(2)} MB');

        if (storageMB < 1) {
          print('  ✓ Safe - well within limits');
        } else if (storageMB < 2) {
          print('  ⚠ Caution - approaching Android SharedPreferences limit');
        } else {
          print('  ❌ Risky - exceeds typical SharedPreferences limit');
          print(
            '     Consider implementing cache size limits or using database',
          );
        }
        print('');
      }

      print('Recommendations:');
      print('1. Implement a maximum cache size (e.g., 5,000 readings)');
      print('2. Add automatic cleanup of oldest readings when limit reached');
      print(
        '3. Consider using SQLite database for large caches (>10,000 readings)',
      );
      print('4. Add UI warning when cache exceeds 1 MB');
      print('5. Implement background sync to clear cache regularly\n');
    });
  });
}
