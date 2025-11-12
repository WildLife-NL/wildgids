class Species {
  final String id;
  final String category;
  final String commonName;
  final String? schema;
  final String? advice;
  final String? behaviour;
  final String? description;
  final String? latinName;
  final String? roleInNature;

  Species({
    required this.id,
    required this.category,
    required this.commonName,
    this.schema,
    this.advice,
    this.behaviour,
    this.description,
    this.latinName,
    this.roleInNature,
  });

  factory Species.fromJson(Map<String, dynamic> json) {
    return Species(
      id: json['ID'] ?? json['id'] ?? '',
      category: json['category'] ?? '',
      commonName: json['commonName'] ?? json['common_name'] ?? '',
      schema: json['\u0024schema'] ?? json[r'\$schema'] ?? null,
      advice: json['advice'] ?? null,
      behaviour: json['behaviour'] ?? null,
      description: json['description'] ?? null,
      latinName: json['name'] ?? null,
      roleInNature: json['roleInNature'] ?? null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'category': category,
      'commonName': commonName,
      '\u0024schema': schema,
      'advice': advice,
      'behaviour': behaviour,
      'description': description,
      'name': latinName,
      'roleInNature': roleInNature,
    };
  }

  @override
  String toString() => 'Species(id: $id, commonName: $commonName)';
}
