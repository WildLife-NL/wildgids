import 'package:wildgids/models/api_models/vicinity.dart';

class TrackingNotice {
  final String text;
  final int? severity;
  final Vicinity? vicinity;

  TrackingNotice(this.text, {this.severity, this.vicinity});

  bool get hasMessage => text.trim().isNotEmpty;
}

class TrackingReadingResponse {
  final String userId;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final Vicinity? vicinity;

  TrackingReadingResponse({
    required this.userId,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    this.vicinity,
  });

  factory TrackingReadingResponse.fromJson(Map<String, dynamic> json) {
    final location = json['location'];
    if (location is! Map) {
      throw FormatException('TrackingReading missing location object');
    }
    final locationMap = location is Map<String, dynamic>
        ? location
        : Map<String, dynamic>.from(location);

    final timestampStr = json['timestamp']?.toString();
    if (timestampStr == null) {
      throw FormatException('TrackingReading missing timestamp');
    }

    Vicinity? vicinity;
    if (json['vicinity'] is Map) {
      final v = json['vicinity'];
      vicinity = Vicinity.fromJson(
        v is Map<String, dynamic> ? v : Map<String, dynamic>.from(v as Map),
      );
    } else if (json['animals'] != null ||
        json['detections'] != null ||
        json['interactions'] != null) {
      vicinity = Vicinity.fromJson(json);
    }

    return TrackingReadingResponse(
      userId: (json['userID'] ?? json['userId'] ?? '').toString(),
      timestamp: DateTime.parse(timestampStr),
      latitude: (locationMap['latitude'] as num).toDouble(),
      longitude: (locationMap['longitude'] as num).toDouble(),
      vicinity: vicinity,
    );
  }
}

abstract class TrackingApiInterface {
  Future<TrackingNotice?> addTrackingReading({
    required double lat,
    required double lon,
    required DateTime timestampUtc,
  });

  Future<List<TrackingReadingResponse>> getMyTrackingReadings();
}
