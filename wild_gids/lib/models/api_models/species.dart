class Species {
  final String id;
  final String category;
  final String commonName;

  Species({required this.id, required this.category, required this.commonName});

  factory Species.fromJson(Map<String, dynamic> json) {
    return Species(
      id: json['ID'],
      category: json['category'],
      commonName: json['commonName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'category': category, 'commonName': commonName};
  }
}
