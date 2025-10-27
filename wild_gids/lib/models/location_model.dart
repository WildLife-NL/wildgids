import 'package:widgets/models/enums/location_source.dart';

class LocationModel {
  final double? latitude;
  final double? longitude;
  final String? placeName;
  final LocationSource? source;

  LocationModel({
    this.latitude,
    this.longitude,
    this.placeName,
    this.source,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'placeName': placeName,
      'source': source?.name,
    };
  }

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble() ?? json['longtitude']?.toDouble(),
      placeName: json['placeName'],
      source:
          json['source'] != null
              ? LocationSource.values.firstWhere(
                  (e) => e.name == json['source'],
                  orElse: () => LocationSource.manual,
                )
              : null,
    );
  }

  LocationModel copyWith({
    double? latitude,
    double? longitude,
    String? placeName,
    LocationSource? source,
  }) {
    return LocationModel(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      placeName: placeName ?? this.placeName,
      source: source ?? this.source,
    );
  }
}
