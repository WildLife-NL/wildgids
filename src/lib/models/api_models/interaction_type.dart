class InteractionType {
  final int id;
  final String name;
  final String description;

  InteractionType({
    required this.id,
    required this.name,
    required this.description,
  });

  factory InteractionType.fromJson(Map<String, dynamic> json) {
    return InteractionType(
      id: _asInt(json['ID'] ?? json['id']),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    // Use API-consistent keys so saved drafts can round-trip via fromJson
    return {'ID': id, 'name': name, 'description': description};
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
