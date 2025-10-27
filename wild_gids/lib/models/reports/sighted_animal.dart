class SightedAnimal {
  final String? speciesId;
  final String? condition;
  final int? count;
  final String? gender;
  final String? age;

  SightedAnimal({
    this.speciesId,
    this.condition,
    this.count,
    this.gender,
    this.age,
  });

  Map<String, dynamic> toJson() {
    return {
      'speciesId': speciesId,
      'condition': condition,
      'count': count,
      'gender': gender,
      'age': age,
    };
  }

  factory SightedAnimal.fromJson(Map<String, dynamic> json) {
    return SightedAnimal(
      speciesId: json['speciesId'],
      condition: json['condition'],
      count: json['count'],
      gender: json['gender'],
      age: json['age'],
    );
  }
}
