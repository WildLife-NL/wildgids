class SightedAnimal {
  final String condition;
  final String lifeStage;
  final String sex;

  SightedAnimal({
    required this.condition,
    required this.lifeStage,
    required this.sex,
  });

  Map<String, dynamic> toJson() => {
    'condition': condition,
    'lifeStage': lifeStage,
    'sex': sex,
  };

  factory SightedAnimal.fromJson(Map<String, dynamic> json) => SightedAnimal(
    condition: json['condition'] ?? '',
    lifeStage: json['lifeStage'] ?? '',
    sex: json['sex'] ?? '',
  );
}

