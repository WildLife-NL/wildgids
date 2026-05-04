class AnimalInfo {
  final String? sex;
  final String? lifeStage;
  final String? condition;

  AnimalInfo({this.sex, this.lifeStage, this.condition});

  factory AnimalInfo.fromJson(Map<String, dynamic> json) {
    return AnimalInfo(
      sex: json['sex']?.toString(),
      lifeStage: json['lifeStage']?.toString(),
      condition: json['condition']?.toString(),
    );
  }
}

class InteractionQueryResult {
  final String id;
  final double lat;
  final double lon;
  final DateTime moment;
  final String? typeName; // e.g., "Sighting"
  final String? speciesName; // e.g., "Vos"
  final String? description; // optional
  final String? userName; // User who reported
  final String? placeName; // Reverse geocoded place name
  final List<AnimalInfo>? involvedAnimals; // Animal details

  InteractionQueryResult({
    required this.id,
    required this.lat,
    required this.lon,
    required this.moment,
    this.typeName,
    this.speciesName,
    this.description,
    this.userName,
    this.placeName,
    this.involvedAnimals,
  });

  /// Defensive JSON parsing:
  /// - accepts id or ID
  /// - accepts location/place with latitude/longitude or lat/lon
  /// - tolerates missing/invalid moment (falls back to now)
  factory InteractionQueryResult.fromJson(Map<String, dynamic> json) {
    final rawId = (json['id'] ?? json['ID'])?.toString();
    if (rawId == null || rawId.isEmpty) {
      throw const FormatException('InteractionQueryResult: missing id');
    }

    // location / place node
    final locNode =
        (json['location'] ?? json['place'] ?? const <String, dynamic>{})
            as Map<String, dynamic>;

    final lat = _asDouble(locNode['latitude'] ?? locNode['lat']);
    final lon = _asDouble(locNode['longitude'] ?? locNode['lon']);

    if (lat == null || lon == null) {
      throw const FormatException(
        'InteractionQueryResult: missing coordinates',
      );
    }

    // moment (ISO8601). If missing/invalid, use now (UTC recommended).
    final rawMoment = json['moment']?.toString();
    final parsedMoment =
        rawMoment != null ? DateTime.tryParse(rawMoment) : null;

    // optional fields
    final typeNode =
        json['type'] as Map<String, dynamic>? ??
        json['interactionType'] as Map<String, dynamic>? ??
        const {};
    final speciesNode = json['species'] as Map<String, dynamic>? ?? const {};
    final userNode = json['user'] as Map<String, dynamic>? ?? const {};
    final placeNode = json['place'] as Map<String, dynamic>? ?? const {};

    // Parse involved animals from reportOfSighting, reportOfCollision, or reportOfDamage
    List<AnimalInfo>? animals;
    final reportOfSighting = json['reportOfSighting'] as Map<String, dynamic>?;
    final reportOfCollision =
        json['reportOfCollision'] as Map<String, dynamic>?;
    final reportOfDamage = json['reportOfDamage'] as Map<String, dynamic>?;

    if (reportOfSighting != null &&
        reportOfSighting['involvedAnimals'] != null) {
      final animalsList = reportOfSighting['involvedAnimals'] as List;
      animals =
          animalsList
              .whereType<Map<String, dynamic>>()
              .map((a) => AnimalInfo.fromJson(a))
              .toList();
    } else if (reportOfCollision != null &&
        reportOfCollision['involvedAnimals'] != null) {
      final animalsList = reportOfCollision['involvedAnimals'] as List;
      animals =
          animalsList
              .whereType<Map<String, dynamic>>()
              .map((a) => AnimalInfo.fromJson(a))
              .toList();
    } else if (reportOfDamage != null &&
        reportOfDamage['involvedAnimals'] != null) {
      final animalsList = reportOfDamage['involvedAnimals'] as List;
      animals =
          animalsList
              .whereType<Map<String, dynamic>>()
              .map((a) => AnimalInfo.fromJson(a))
              .toList();
    }

    return InteractionQueryResult(
      id: rawId,
      lat: lat,
      lon: lon,
      moment: (parsedMoment ?? DateTime.now()).toUtc(),
      typeName: (typeNode['name'] ?? typeNode['displayName'])?.toString(),
      speciesName:
          (speciesNode['commonName'] ?? speciesNode['name'])?.toString(),
      description: json['description']?.toString(),
      userName: (userNode['name'] ?? userNode['username'])?.toString(),
      placeName: placeNode['name']?.toString(),
      involvedAnimals: animals,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'location': {'latitude': lat, 'longitude': lon},
    'moment': moment.toIso8601String(),
    if (typeName != null) 'type': {'name': typeName},
    if (speciesName != null) 'species': {'commonName': speciesName},
    if (description != null) 'description': description,
    if (userName != null) 'user': {'name': userName},
    if (placeName != null) 'place': {'name': placeName},
  };

  static double? _asDouble(Object? v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}
