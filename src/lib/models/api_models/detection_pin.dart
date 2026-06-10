class DetectionPin {
  final String id;
  final String? deviceType;
  final String? label;
  final String? sex;
  final String? lifeStage;
  final String? condition;
  final String? reportedByName;
  final double lat;
  final double lon;
  final DateTime detectedAt;
  final double? confidence;
  final String? speciesLatinName;

  DetectionPin({
    required this.id,
    required this.lat,
    required this.lon,
    required this.detectedAt,
    this.deviceType,
    this.label,
    this.sex,
    this.lifeStage,
    this.condition,
    this.reportedByName,
    this.confidence,
    this.speciesLatinName,
  });

  factory DetectionPin.fromJson(Map<String, dynamic> j) {
    final loc = _locationMap(j['location'] ?? j['place']);
    if (loc == null) {
      throw const FormatException('DetectionPin: missing location');
    }
    
    final lat = _asDouble(loc['latitude'] ?? loc['lat']);
    final lon = _asDouble(loc['longitude'] ?? loc['lon']);
    if (lat == null || lon == null) {
      throw const FormatException('DetectionPin: missing coordinates');
    }

    final id = (j['id'] ??
            j['ID'] ??
            j['sensorID'] ??
            j['deploymentID'])
        ?.toString();
    if (id == null || id.isEmpty) {
      throw const FormatException('DetectionPin: missing id');
    }

    final species = j['species'];
    final speciesMap = species is Map<String, dynamic>
        ? species
        : species is Map
            ? Map<String, dynamic>.from(species)
            : null;

    final speciesLatinName = speciesMap?['latinName']?.toString() ??
      speciesMap?['latin_name']?.toString() ??
      speciesMap?['scientificName']?.toString() ??
      speciesMap?['name']?.toString();

    // Additional optional animal detail fields
    final sex = j['sex']?.toString() ??
      speciesMap?['sex']?.toString() ??
      speciesMap?['gender']?.toString();

    final lifeStage = j['lifeStage']?.toString() ??
      speciesMap?['lifeStage']?.toString() ??
      speciesMap?['ageClass']?.toString();

    final condition = j['condition']?.toString() ??
      speciesMap?['condition']?.toString() ??
      speciesMap?['conditionStatus']?.toString();

    final userNode = j['user'];
    final userMap = userNode is Map<String, dynamic>
      ? userNode
      : userNode is Map
        ? Map<String, dynamic>.from(userNode)
        : null;

    final reportedByName = (j['reportedByName'] ??
        j['reportedBy'] ??
        j['reporterName'] ??
        j['reporter'] ??
        j['createdBy'] ??
        j['createdByName'])
      ?.toString() ??
      (userMap?['name'] ?? userMap?['username'])?.toString();

    final ts =
        (j['moment'] ?? j['timestamp'] ?? j['start'] ?? j['end'])?.toString();

   return DetectionPin(
  id: id,
  lat: lat,
  lon: lon,
  detectedAt:
      DateTime.tryParse(ts ?? '')?.toUtc() ?? DateTime.now().toUtc(),
  deviceType: (j['deviceType'] ?? j['sensorType'])?.toString(),
  label: j['label']?.toString() ??
      speciesMap?['commonName']?.toString() ??
      speciesMap?['name']?.toString(),
  sex: sex,
  lifeStage: lifeStage,
  condition: condition,
  reportedByName: reportedByName,
  speciesLatinName: speciesLatinName,

  confidence: (j['confidence'] as num?)?.toDouble(),
);

    
  }

  static Map<String, dynamic>? _locationMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static double? _asDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
