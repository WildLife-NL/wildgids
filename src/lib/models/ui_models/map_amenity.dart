enum AmenityCategory {
  toilet('toilet', 'Toiletten'),
  parking('parking', 'Parkeren'),
  drinkingWater('drinking_water', 'Drinkwater'),
  viewpoint('viewpoint', 'Uitzichtpunten'),
  birdHide('bird_hide', 'Vogelkijkhutten'),
  entrance('entrance', 'Ingangen'),
  visitorCentre('visitor_centre', 'Bezoekerscentra'),
  estate('estate', 'Buitenplaatsen'),
  pointOfInterest('point_of_interest', 'Bezienswaardigheden');

  const AmenityCategory(this.id, this.label);
  final String id;
  final String label;

  static AmenityCategory parse(Object? value) => values.firstWhere(
    (category) => category.id == value,
    orElse: () => throw FormatException('Unknown amenity category: $value'),
  );
}

class MapAmenity {
  const MapAmenity({
    required this.id,
    required this.livingLabId,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    this.isExample = false,
  });

  final String id;
  final String livingLabId;
  final String name;
  final AmenityCategory category;
  final double latitude;
  final double longitude;
  final bool isExample;

  factory MapAmenity.fromJson(
    Map<String, dynamic> json, {
    required String livingLabId,
  }) {
    String requiredText(String key) {
      final value = json[key];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('Missing amenity $key');
      }
      return value.trim();
    }

    double coordinate(String key, double limit) {
      final value = json[key];
      if (value is! num || !value.isFinite || value.abs() > limit) {
        throw FormatException('Invalid amenity $key: $value');
      }
      return value.toDouble();
    }

    final category = AmenityCategory.parse(json['type']);
    final latitude = coordinate('latitude', 90);
    final longitude = coordinate('longitude', 180);
    if (json.containsKey('example') && json['example'] is! bool) {
      throw const FormatException('Example must be true or false');
    }
    return MapAmenity(
      // Local marker identity stays the same when rows are reordered or renamed.
      id: '$livingLabId:${category.id}:$latitude:$longitude',
      livingLabId: livingLabId,
      name: requiredText('name'),
      category: category,
      latitude: latitude,
      longitude: longitude,
      isExample: json['example'] == true,
    );
  }
}

class AmenityCatalog {
  const AmenityCatalog(this.amenities);
  final List<MapAmenity> amenities;

  factory AmenityCatalog.fromJson(
    Object? value, {
    required String livingLabId,
  }) {
    if (value is! List || livingLabId.trim().isEmpty) {
      throw const FormatException('Expected a park amenities list');
    }
    final ids = <String>{};
    final amenities = <MapAmenity>[];
    for (final entry in value) {
      if (entry is! Map<String, dynamic>) {
        throw const FormatException('Invalid amenity entry');
      }
      final amenity = MapAmenity.fromJson(entry, livingLabId: livingLabId);
      if (!ids.add(amenity.id)) {
        throw FormatException('Duplicate amenity location: ${amenity.name}');
      }
      amenities.add(amenity);
    }
    return AmenityCatalog(List.unmodifiable(amenities));
  }
}
