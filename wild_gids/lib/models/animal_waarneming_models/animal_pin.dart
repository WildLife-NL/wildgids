class AnimalPin {
  final String id;
  final String? speciesName;
  final double lat;
  final double lon;
  final DateTime seenAt;

  AnimalPin({
    required this.id,
    required this.lat,
    required this.lon,
    required this.seenAt,
    this.speciesName,
  });

  factory AnimalPin.fromJson(Map<String, dynamic> j) {
    final loc = (j['location'] ?? j['place'] ?? {}) as Map<String, dynamic>;
    final id = (j['id'] ?? j['ID']).toString();
    final lat = (loc['latitude'] ?? loc['lat']) as num;
    final lon = (loc['longitude'] ?? loc['lon']) as num;
    final ts = (j['moment'] ?? j['timestamp'] ?? j['seenAt'])?.toString();
    return AnimalPin(
      id: id,
      lat: lat.toDouble(),
      lon: lon.toDouble(),
      seenAt: DateTime.tryParse(ts ?? '')?.toUtc() ?? DateTime.now().toUtc(),
      speciesName: (j['species']?['commonName'] ?? j['species']?['name'])?.toString(),
    );
  }
}
