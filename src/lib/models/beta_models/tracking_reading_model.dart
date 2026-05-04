class TrackingReading {
  final double latitude;
  final double longitude;
  final DateTime timestampUtc;

  TrackingReading({
    required this.latitude,
    required this.longitude,
    required this.timestampUtc,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'timestampUtc': timestampUtc.toIso8601String(),
  };

  factory TrackingReading.fromJson(Map<String, dynamic> json) {
    return TrackingReading(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestampUtc: DateTime.parse(json['timestampUtc'] as String),
    );
  }

  @override
  String toString() {
    return 'TrackingReading(lat: $latitude, lon: $longitude, time: ${timestampUtc.toIso8601String()})';
  }
}
