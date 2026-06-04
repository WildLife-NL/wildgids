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
  /// Map pin: [eventLat]/[eventLon] (place) or fallback to report GPS.
  final double lat;
  final double lon;
  /// GPS when the interaction was reported ([location] in the API).
  final double? reportLat;
  final double? reportLon;
  /// Where the interaction happened ([place] in the API).
  final double? eventLat;
  final double? eventLon;
  final DateTime moment;
  final String? typeName; // e.g., "Sighting"
  final int? typeId;
  final bool hasReportOfSighting;
  final String? speciesName; // e.g., "Vos"
  final String? speciesLatinName;
  final String? description; // optional
  final String? userName; // User who reported
  final String? placeName; // Reverse geocoded place name
  final List<AnimalInfo>? involvedAnimals; // Animal details

  /// User-submitted waarneming (not a collar/tracker animal from [vicinity.animals]).
  bool get isUserWaarneming {
    if (hasReportOfSighting) return true;
    if (typeId == 1) return true;
    final type = typeName?.toLowerCase() ?? '';
    return type.contains('waarneming') || type.contains('sighting');
  }

  /// Stable key for merging pins (avoids collapsing rows when [id] repeats).
  String get dedupeKey =>
      id.isNotEmpty
          ? id
          : '${lat.toStringAsFixed(5)}|${lon.toStringAsFixed(5)}|${moment.toUtc().millisecondsSinceEpoch}';

  InteractionQueryResult({
    required this.id,
    required this.lat,
    required this.lon,
    this.reportLat,
    this.reportLon,
    this.eventLat,
    this.eventLon,
    required this.moment,
    this.typeName,
    this.typeId,
    this.hasReportOfSighting = false,
    this.speciesName,
    this.speciesLatinName,
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

    final reportCoords = _coordsFromNode(locationNode);
    final eventCoords = _coordsFromNode(placeNodeForCoords);
    final mapCoords = eventCoords ?? reportCoords;
    if (mapCoords == null) {
      throw const FormatException(
        'InteractionQueryResult: missing coordinates',
      );
    }
    final lat = mapCoords.lat;
    final lon = mapCoords.lon;

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

    final typeIdRaw =
        typeNode['id'] ??
        typeNode['ID'] ??
        typeNode['typeID'] ??
        typeNode['typeId'];
    final typeId = typeIdRaw is int
        ? typeIdRaw
        : int.tryParse(typeIdRaw?.toString() ?? '');

    return InteractionQueryResult(
      id: rawId,
      lat: lat,
      lon: lon,
      reportLat: reportCoords?.lat,
      reportLon: reportCoords?.lon,
      eventLat: eventCoords?.lat,
      eventLon: eventCoords?.lon,
      moment: parsedMoment ?? DateTime.now().toUtc(),
      typeName: (typeNode['name'] ??
              typeNode['displayName'] ??
              (json['type'] is String ? json['type'] : null))
          ?.toString(),
      typeId: typeId,
      hasReportOfSighting: reportOfSighting.isNotEmpty,
      speciesName:
          (speciesNode['commonName'] ?? speciesNode['name'])?.toString(),
        speciesLatinName: (speciesNode['latinName'] ??
            speciesNode['latin_name'] ??
                speciesNode['scientificName'] ??
                speciesNode['name'])
          ?.toString(),
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
    if (speciesLatinName != null) 'speciesLatinName': speciesLatinName,
    if (description != null) 'description': description,
    if (userName != null) 'user': {'name': userName},
    if (placeName != null) 'place': {'name': placeName},
  };

  /// OpenAPI: [location] = reported from, [place] = where it happened.
  static ({double lat, double lon})? _coordsFromNode(
    Map<String, dynamic> node,
  ) {
    if (node.isEmpty) return null;

    final lat = _asDouble(node['latitude'] ?? node['lat']);
    final lon = _asDouble(
      node['longitude'] ?? node['lon'] ?? node['longtitude'],
    );

    if (lat == null || lon == null) return null;
    if (!lat.isFinite || !lon.isFinite) return null;
    if (lat.abs() < 1e-6 && lon.abs() < 1e-6) return null;
    return (lat: lat, lon: lon);
  }

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
