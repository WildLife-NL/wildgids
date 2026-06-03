class AnimalPin {
  final String id;
  final String? speciesName;
  final String? speciesLatinName;
  final int? animalCount;
  final double lat;
  final double lon;
  final DateTime seenAt;
  final String? locationLabel;
  final String? reportType;
  final String? reportedByName;
  final String? groupSummary;
  final String? imageUrl;
  

  AnimalPin({
    required this.id,
    required this.lat,
    required this.lon,
    required this.seenAt,
    this.speciesName,
    this.speciesLatinName,
    this.animalCount,
    this.locationLabel,
    this.reportType,
    this.reportedByName,
    this.groupSummary,
    this.imageUrl,
  });

  factory AnimalPin.fromJson(Map<String, dynamic> j) {
    final loc = _locationMap(j['location'] ?? j['place']);
    if (loc == null) {
      throw const FormatException('AnimalPin: missing location');
    }

    final lat = _asDouble(loc['latitude'] ?? loc['lat']);
    final lon = _asDouble(loc['longitude'] ?? loc['lon']);
    if (lat == null || lon == null) {
      throw const FormatException('AnimalPin: missing coordinates');
    }

    final id = (j['id'] ?? j['ID'])?.toString();
    if (id == null || id.isEmpty) {
      throw const FormatException('AnimalPin: missing id');
    }

    final species = j['species'];
    final speciesMap = species is Map<String, dynamic>
        ? species
        : species is Map
            ? Map<String, dynamic>.from(species)
            : null;

    final user = j['user'];
    final userMap = user is Map<String, dynamic>
        ? user
        : user is Map
            ? Map<String, dynamic>.from(user)
            : null;

    final ts =
        (j['locationTimestamp'] ?? j['moment'] ?? j['timestamp'] ?? j['seenAt'])
            ?.toString();

    return AnimalPin(
      id: id,
      lat: lat,
      lon: lon,
      seenAt: DateTime.tryParse(ts ?? '')?.toUtc() ?? DateTime.now().toUtc(),
      speciesName: speciesMap?['commonName']?.toString() ??
          speciesMap?['name']?.toString(),
      speciesLatinName: speciesMap?['name']?.toString(),
      animalCount: _extractAnimalCount(j),
      imageUrl: j['imageUrl']?.toString(),
      reportedByName: userMap?['name']?.toString(),
      groupSummary: _buildGroupSummary(j),
      locationLabel: j['locationLabel']?.toString(),
      reportType: j['reportType']?.toString() ?? 'waarneming',
    );
  }

  static int? _extractAnimalCount(Map<String, dynamic> j) {
    final report = j['reportOfSighting'];
    final reportMap = report is Map<String, dynamic>
        ? report
        : report is Map
            ? Map<String, dynamic>.from(report)
            : null;

    final animals = reportMap?['involvedAnimals'];
    if (animals is List && animals.isNotEmpty) {
      return animals.length;
    }

    final raw = j['animalCount'] ?? j['count'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '');
  }

  static String? _buildGroupSummary(Map<String, dynamic> j) {
    final count = _extractAnimalCount(j);
    if (count == null || count <= 0) return null;
    return '$count ${count == 1 ? 'dier' : 'dieren'}';
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