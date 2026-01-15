class ReportLocation {
  final double? latitude;
  final double? longtitude;
  final String? cityName;
  final String? streetName;
  final String? houseNumber;

  ReportLocation({
    this.latitude,
    this.longtitude,
    this.cityName,
    this.streetName,
    this.houseNumber,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longtitude': longtitude,
    'cityName': cityName,
    'streetName': streetName,
    'houseNumber': houseNumber,
  };

  factory ReportLocation.fromJson(Map<String, dynamic> json) => ReportLocation(
    latitude: json['latitude'],
    longtitude: json['longtitude'],
    cityName: json['cityName'],
    streetName: json['streetName'],
    houseNumber: json['houseNumber'],
  );
}
