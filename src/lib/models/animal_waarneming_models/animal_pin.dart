class AnimalPin {
  final String id;
  final String? speciesName;
  final String? speciesLatinName;
  final int? animalCount;
  final List<AnimalObservedDetail>? involvedAnimals;
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
    this.involvedAnimals,
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

    final speciesLatinName = speciesMap?['latinName']?.toString() ??
      speciesMap?['latin_name']?.toString() ??
      speciesMap?['scientificName']?.toString() ??
      speciesMap?['name']?.toString() ??
      j['speciesLatinName']?.toString() ??
      j['latinName']?.toString() ??
      j['latin_name']?.toString();

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
      speciesLatinName: speciesLatinName,
      animalCount: _extractAnimalCount(j),
      involvedAnimals: _extractInvolvedAnimals(j),
      imageUrl: j['imageUrl']?.toString(),
      reportedByName: userMap?['name']?.toString(),
      groupSummary: _buildGroupSummary(j),
      locationLabel: j['locationLabel']?.toString(),
      reportType: j['reportType']?.toString() ?? 'waarneming',
    );
  }

  static int? _extractAnimalCount(Map<String, dynamic> j) {
    final listCount = _extractInvolvedAnimals(j)?.length;

    final rawCandidates = <Object?>[
      j['animalCount'],
      j['count'],
      j['reportOfSighting'] is Map
          ? (j['reportOfSighting'] as Map)['animalCount']
          : null,
      j['reportOfCollision'] is Map
          ? (j['reportOfCollision'] as Map)['animalCount']
          : null,
      j['reportOfDamage'] is Map
          ? (j['reportOfDamage'] as Map)['animalCount']
          : null,
    ];

    int? rawCount;
    for (final raw in rawCandidates) {
      final parsed = _asInt(raw);
      if (parsed != null) {
        rawCount = parsed;
        break;
      }
    }

    if (rawCount != null && listCount != null) {
      return rawCount > listCount ? rawCount : listCount;
    }

    return rawCount ?? listCount;
  }

  static String? _buildGroupSummary(Map<String, dynamic> j) {
    final count = _extractAnimalCount(j);
    if (count == null || count <= 0) return null;
    return '$count ${count == 1 ? 'dier' : 'dieren'}';
  }

  static List<AnimalObservedDetail>? _extractInvolvedAnimals(
    Map<String, dynamic> j,
  ) {
    final candidates = <Object?>[
      j['reportOfSighting'],
      j['reportOfCollision'],
      j['reportOfDamage'],
    ];

    for (final report in candidates) {
      final reportMap = report is Map<String, dynamic>
          ? report
          : report is Map
              ? Map<String, dynamic>.from(report)
              : null;

      final animals = reportMap?['involvedAnimals'];
      if (animals is List && animals.isNotEmpty) {
        final parsed = animals
            .whereType<Map>()
            .map((a) => AnimalObservedDetail.fromJson(
                  a is Map<String, dynamic>
                      ? a
                      : Map<String, dynamic>.from(a),
                ))
            .toList();
        if (parsed.isNotEmpty) return parsed;
      }
    }

    final topLevel = j['involvedAnimals'];
    if (topLevel is List && topLevel.isNotEmpty) {
      final parsed = topLevel
          .whereType<Map>()
          .map((a) => AnimalObservedDetail.fromJson(
                a is Map<String, dynamic>
                    ? a
                    : Map<String, dynamic>.from(a),
              ))
          .toList();
      if (parsed.isNotEmpty) return parsed;
    }

    return null;
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

  static int? _asInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}

class AnimalObservedDetail {
  final String? sex;
  final String? lifeStage;
  final String? condition;

  const AnimalObservedDetail({
    this.sex,
    this.lifeStage,
    this.condition,
  });

  factory AnimalObservedDetail.fromJson(Map<String, dynamic> json) {
    return AnimalObservedDetail(
      sex: (json['sex'] ?? json['gender'])?.toString(),
      lifeStage: (json['lifeStage'] ?? json['life_stage'])?.toString(),
      condition: json['condition']?.toString(),
    );
  }
}