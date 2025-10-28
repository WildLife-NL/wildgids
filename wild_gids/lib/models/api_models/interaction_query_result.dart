class InteractionQueryResult {
  final String id;
  final double lat;
  final double lon;
  final DateTime moment;
  final String? typeName;     // e.g., "Sighting"
  final String? speciesName;  // e.g., "Vos"
  final String? description;  // optional

  InteractionQueryResult({
    required this.id,
    required this.lat,
    required this.lon,
    required this.moment,
    this.typeName,
    this.speciesName,
    this.description,
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
    final locNode = (json['location'] ??
        json['place'] ??
        const <String, dynamic>{}) as Map<String, dynamic>;

    final lat = _asDouble(locNode['latitude'] ?? locNode['lat']);
    final lon = _asDouble(locNode['longitude'] ?? locNode['lon']);

    if (lat == null || lon == null) {
      throw const FormatException(
        'InteractionQueryResult: missing coordinates',
      );
    }

    // moment (ISO8601). If missing/invalid, use now (UTC recommended).
    final rawMoment = json['moment']?.toString();
    final parsedMoment = rawMoment != null ? DateTime.tryParse(rawMoment) : null;

    // optional fields
    final typeNode = json['type'] as Map<String, dynamic>? ??
        json['interactionType'] as Map<String, dynamic>? ??
        const {};
    final speciesNode = json['species'] as Map<String, dynamic>? ?? const {};

    return InteractionQueryResult(
      id: rawId,
      lat: lat,
      lon: lon,
      moment: (parsedMoment ?? DateTime.now()).toUtc(),
      typeName: (typeNode['name'] ?? typeNode['displayName'])?.toString(),
      speciesName:
          (speciesNode['commonName'] ?? speciesNode['name'])?.toString(),
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'location': {
          'latitude': lat,
          'longitude': lon,
        },
        'moment': moment.toIso8601String(),
        if (typeName != null) 'type': {'name': typeName},
        if (speciesName != null) 'species': {'commonName': speciesName},
        if (description != null) 'description': description,
      };

  static double? _asDouble(Object? v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}
