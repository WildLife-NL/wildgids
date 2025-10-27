class ReportLocation {
  final double? latitude;
  final double? longitude;
  final String? placeName;

  ReportLocation({
    this.latitude,
    this.longitude,
    this.placeName,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'placeName': placeName,
    };
  }

  factory ReportLocation.fromJson(Map<String, dynamic> json) {
    return ReportLocation(
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      placeName: json['placeName'],
    );
  }
}
