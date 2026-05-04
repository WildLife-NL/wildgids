class DetectionPin {
  final String id;
  final String? deviceType; // camera, acoustic, etc.
  final String? label; // optional class/species label
  final double lat;
  final double lon;
  final DateTime detectedAt;
  final double? confidence; // 0..1 or %

  DetectionPin({
    required this.id,
    required this.lat,
    required this.lon,
    required this.detectedAt,
    this.deviceType,
    this.label,
    this.confidence,
  });

  factory DetectionPin.fromJson(Map<String, dynamic> j) {
    final loc = (j['location'] ?? j['place'] ?? {}) as Map<String, dynamic>;
    final id = (j['id'] ?? j['ID']).toString();
    final lat = (loc['latitude'] ?? loc['lat']) as num;
    final lon = (loc['longitude'] ?? loc['lon']) as num;
    final ts = (j['moment'] ?? j['timestamp'])?.toString();
    return DetectionPin(
      id: id,
      lat: lat.toDouble(),
      lon: lon.toDouble(),
      detectedAt:
          DateTime.tryParse(ts ?? '')?.toUtc() ?? DateTime.now().toUtc(),
      deviceType: j['deviceType']?.toString(),
      label: j['label']?.toString(),
      confidence: (j['confidence'] as num?)?.toDouble(),
    );
  }
}
