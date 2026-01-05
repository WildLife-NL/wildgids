class TrackingNotice {
  final String text;
  final int? severity;
  TrackingNotice(this.text, {this.severity});
}

class TrackingReadingResponse {
  final String userId;
  final DateTime timestamp;
  final double latitude;
  final double longitude;

  TrackingReadingResponse({
    required this.userId,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
  });

  factory TrackingReadingResponse.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>;
    final timestampStr = json['timestamp'] as String;
    final parsed = DateTime.parse(timestampStr);
    return TrackingReadingResponse(
      userId: json['userID'] as String,
      timestamp: parsed,
      latitude: (location['latitude'] as num).toDouble(),
      longitude: (location['longitude'] as num).toDouble(),
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
