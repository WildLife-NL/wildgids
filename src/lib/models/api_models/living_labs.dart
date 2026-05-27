import 'package:wildgids/models/api_models/location.dart';

class LivingLabs {
  String id;
  List<Location>? definition;
  String name;
  String commonName;

  LivingLabs({
    required this.id,
    required this.definition,
    required this.name,
    required this.commonName,
  });

  factory LivingLabs.fromJson(Map<String, dynamic> json) => LivingLabs(
    id: json['ID']?.toString() ?? '',
    definition: _parseDefinition(json['definition']),
    name: json['name']?.toString() ?? '',
    commonName: json['commonName']?.toString() ?? '',
  );

  static List<Location>? _parseDefinition(dynamic raw) {
    if (raw == null || raw is! List) return null;
    return raw
        .whereType<Map>()
        .map(
          (x) => Location.fromJson(
            x is Map<String, dynamic> ? x : Map<String, dynamic>.from(x),
          ),
        )
        .toList();
  }

  Map<String, dynamic> toJson() {
    return {
      "ID": id,
      "definition":
          definition != null
              ? List<dynamic>.from(definition!.map((x) => x.toJson()))
              : null,
      "name": name,
      "commonName": commonName,
    };
  }
}

