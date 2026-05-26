import 'package:wildgids/utils/api_datetime.dart';

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

    // location / place node (backend shapes vary across endpoints)
    final locationNode = _asMap(json['location']);
    final placeNodeForCoords = _asMap(json['place']);

    // Prefer `place` (where the interaction happened) over `location` (reported from).
    final lat = _asDouble(
      placeNodeForCoords['latitude'] ??
          placeNodeForCoords['lat'] ??
          locationNode['latitude'] ??
          locationNode['lat'],
    );
    final lon = _asDouble(
      placeNodeForCoords['longitude'] ??
          placeNodeForCoords['lon'] ??
          placeNodeForCoords['longtitude'] ??
          locationNode['longitude'] ??
          locationNode['lon'] ??
          locationNode['longtitude'],
    );

    if (lat == null || lon == null) {
      throw const FormatException(
        'InteractionQueryResult: missing coordinates',
      );
    }

    // moment (when it happened); timestamp (when reported) as fallback.
    final rawMoment =
        json['moment']?.toString() ?? json['timestamp']?.toString();
    final parsedMoment =
        rawMoment != null && rawMoment.isNotEmpty
            ? ApiDateTime.parse(rawMoment)
            : null;

    // optional fields
    final typeNode =
        _asMap(json['type']).isNotEmpty
            ? _asMap(json['type'])
            : _asMap(json['interactionType']);
    final speciesNode = _asMap(json['species']);
    final userNode = _asMap(json['user']);
    final placeNode = _asMap(json['place']);

    // Parse involved animals from reportOfSighting, reportOfCollision, or reportOfDamage
    List<AnimalInfo>? animals;
    final reportOfSighting = _asMap(json['reportOfSighting']);
    final reportOfCollision = _asMap(json['reportOfCollision']);
    final reportOfDamage = _asMap(json['reportOfDamage']);

    if (reportOfSighting.isNotEmpty &&
        reportOfSighting['involvedAnimals'] is List) {
      final animalsList = reportOfSighting['involvedAnimals'] as List;
      animals =
          animalsList
              .whereType<Map>()
              .map(
                (a) => AnimalInfo.fromJson(
                  a is Map<String, dynamic>
                      ? a
                      : Map<String, dynamic>.from(a),
                ),
              )
              .toList();
    } else if (reportOfCollision.isNotEmpty &&
        reportOfCollision['involvedAnimals'] is List) {
      final animalsList = reportOfCollision['involvedAnimals'] as List;
      animals =
          animalsList
              .whereType<Map>()
              .map(
                (a) => AnimalInfo.fromJson(
                  a is Map<String, dynamic>
                      ? a
                      : Map<String, dynamic>.from(a),
                ),
              )
              .toList();
    } else if (reportOfDamage.isNotEmpty &&
        reportOfDamage['involvedAnimals'] is List) {
      final animalsList = reportOfDamage['involvedAnimals'] as List;
      animals =
          animalsList
              .whereType<Map>()
              .map(
                (a) => AnimalInfo.fromJson(
                  a is Map<String, dynamic>
                      ? a
                      : Map<String, dynamic>.from(a),
                ),
              )
              .toList();
    }

    return InteractionQueryResult(
      id: rawId,
      lat: lat,
      lon: lon,
      moment: parsedMoment ?? DateTime.now().toUtc(),
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

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map(
        (key, val) => MapEntry(key.toString(), val),
      );
    }
    return const <String, dynamic>{};
  }
}
