class Possesion {
  final String? possesionID;
  final String? possesionName;
  final String? category;

  Possesion({
    this.possesionID, 
    required this.possesionName, 
    this.category
  });

  Map<String, dynamic> toJson() => {
    'ID': possesionID,
    'name': possesionName == '' ? null : possesionName,
    'category': category,
  };
  factory Possesion.fromJson(Map<String, dynamic> json) => Possesion(
    possesionID: json['ID'],
    possesionName: json['name'],
    category: json['category'],
  );
}


