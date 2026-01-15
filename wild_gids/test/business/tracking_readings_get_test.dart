import 'package:flutter_test/flutter_test.dart';
import 'package:wildgids/interfaces/data_apis/tracking_api_interface.dart';

// Mock TrackingApi for testing
class MockTrackingApi implements TrackingApiInterface {
  final List<Map<String, dynamic>> mockData;
  
  MockTrackingApi(this.mockData);

  @override
  Future<TrackingNotice?> addTrackingReading({
    required double lat,
    required double lon,
    required DateTime timestampUtc,
  }) async {
    return null;
  }

  @override
  Future<List<TrackingReadingResponse>> getMyTrackingReadings() async {
    // Simulate API response
    return mockData
        .map((json) => TrackingReadingResponse.fromJson(json))
        .toList();
  }
}

void main() {
  group('Get My Tracking Readings', () {
    test('Parse tracking reading response correctly', () {
      final json = {
        'userID': 'a16f7ab3-f9e3-4753-af2b-55710a69959c',
        'timestamp': '2025-12-03T11:08:31.386369Z',
        'location': {
          'latitude': 51.7000894,
          'longitude': 5.2701216,
        },
      };

      final reading = TrackingReadingResponse.fromJson(json);

      expect(reading.userId, 'a16f7ab3-f9e3-4753-af2b-55710a69959c');
      expect(reading.latitude, 51.7000894);
      expect(reading.longitude, 5.2701216);
      expect(reading.timestamp.year, 2025);
      expect(reading.timestamp.month, 12);
      expect(reading.timestamp.day, 3);
    });

    test('Get multiple tracking readings', () async {
      final mockData = [
        {
          'userID': 'user-123',
          'timestamp': '2025-12-03T10:00:00Z',
          'location': {'latitude': 51.7, 'longitude': 5.27},
        },
        {
          'userID': 'user-123',
          'timestamp': '2025-12-03T11:00:00Z',
          'location': {'latitude': 51.71, 'longitude': 5.28},
        },
      ];

      final api = MockTrackingApi(mockData);
      final readings = await api.getMyTrackingReadings();

      expect(readings.length, 2);
      expect(readings[0].latitude, 51.7);
      expect(readings[1].latitude, 51.71);
    });

    test('Handle empty tracking readings list', () async {
      final api = MockTrackingApi([]);
      final readings = await api.getMyTrackingReadings();

      expect(readings, isEmpty);
    });
  });
}

