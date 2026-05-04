class Species {
  final String id;
  final String category;
  final String commonName;
  final String? latinName;
  final String? description;
  final String? behaviour;
  final String? roleInNature;
  final String? advice;

  Species({
    required this.id,
    required this.category,
    required this.commonName,
    this.latinName,
    this.description,
    this.behaviour,
    this.roleInNature,
    this.advice,
  });

  factory Species.fromJson(Map<String, dynamic> json) {
    return Species(
      id: (json['ID'] ?? json['id'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      commonName: (json['commonName'] ?? json['name'] ?? '').toString(),
      latinName: (json['latinName'] ?? json['latin_name'])?.toString(),
      description: json['description']?.toString(),
      behaviour: (json['behaviour'] ?? json['behavior'])?.toString(),
      roleInNature: (json['roleInNature'] ?? json['role_in_nature'])?.toString(),
      advice: json['advice']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'commonName': commonName,
      if (latinName != null) 'latinName': latinName,
      if (description != null) 'description': description,
      if (behaviour != null) 'behaviour': behaviour,
      if (roleInNature != null) 'roleInNature': roleInNature,
      if (advice != null) 'advice': advice,
    };
  }
}
