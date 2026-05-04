import 'package:wildgids/models/enums/location_source.dart';

class LocationModel {
  final double? latitude;
  final double? longitude;
  final String? cityName;
  final String? streetName;
  final String? houseNumber;
  final LocationSource source;

  LocationModel({
    this.latitude,
    this.longitude,
    this.cityName,
    this.streetName,
    this.houseNumber,
    this.source = LocationSource.unknown,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'cityName': cityName,
    'streetName': streetName,
    'houseNumber': houseNumber,
    'source': source.toString(),
  };

  factory LocationModel.fromJson(Map<String, dynamic> json) => LocationModel(
    latitude: json['latitude'],
    longitude: json['longitude'],
    cityName: json['cityName'],
    streetName: json['streetName'],
    houseNumber: json['houseNumber'],
    source: LocationSource.values.firstWhere(
      (e) => e.toString() == json['source'],
      orElse: () => LocationSource.unknown,
    ),
  );

  // Factory constructors for current and selected locations
  factory LocationModel.currentLocation({
    required double latitude,
    required double longitude,
    String? cityName,
    String? streetName,
    String? houseNumber,
  }) => LocationModel(
    latitude: latitude,
    longitude: longitude,
    cityName: cityName,
    streetName: streetName,
    houseNumber: houseNumber,
    source: LocationSource.system,
  );

  factory LocationModel.selectedLocation({
    required double latitude,
    required double longitude,
    String? cityName,
    String? streetName,
    String? houseNumber,
  }) => LocationModel(
    latitude: latitude,
    longitude: longitude,
    cityName: cityName,
    streetName: streetName,
    houseNumber: houseNumber,
    source: LocationSource.manual,
  );
}

