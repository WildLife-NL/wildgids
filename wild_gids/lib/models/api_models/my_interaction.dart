class MyInteractionLocation {
  final double latitude;
  final double longitude;

  MyInteractionLocation({required this.latitude, required this.longitude});

  factory MyInteractionLocation.fromJson(Map<String, dynamic> json) {
    return MyInteractionLocation(
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'latitude': latitude, 'longitude': longitude};
  }
}

class InvolvedAnimal {
  final String sex;
  final String lifeStage;
  final String condition;

  InvolvedAnimal({
    required this.sex,
    required this.lifeStage,
    required this.condition,
  });

  factory InvolvedAnimal.fromJson(Map<String, dynamic> json) {
    return InvolvedAnimal(
      sex: json['sex'] ?? 'unknown',
      lifeStage: json['lifeStage'] ?? 'unknown',
      condition: json['condition'] ?? 'other',
    );
  }

  Map<String, dynamic> toJson() {
    return {'sex': sex, 'lifeStage': lifeStage, 'condition': condition};
  }
}

class ReportOfCollision {
  final List<InvolvedAnimal> involvedAnimals;
  final int estimatedDamage;
  final String intensity;
  final String urgency;

  ReportOfCollision({
    required this.involvedAnimals,
    required this.estimatedDamage,
    required this.intensity,
    required this.urgency,
  });

  factory ReportOfCollision.fromJson(Map<String, dynamic> json) {
    return ReportOfCollision(
      involvedAnimals: (json['involvedAnimals'] as List?)
              ?.map((e) => InvolvedAnimal.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      estimatedDamage: json['estimatedDamage'] ?? 0,
      intensity: json['intensity'] ?? 'medium',
      urgency: json['urgency'] ?? 'medium',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'involvedAnimals': involvedAnimals.map((e) => e.toJson()).toList(),
      'estimatedDamage': estimatedDamage,
      'intensity': intensity,
      'urgency': urgency,
    };
  }
}

class ReportOfDamage {
  final String belonging;
  final String impactType;
  final int impactValue;
  final int estimatedDamage;
  final int estimatedLoss;

  ReportOfDamage({
    required this.belonging,
    required this.impactType,
    required this.impactValue,
    required this.estimatedDamage,
    required this.estimatedLoss,
  });

  factory ReportOfDamage.fromJson(Map<String, dynamic> json) {
    return ReportOfDamage(
      belonging: json['belonging'] ?? '',
      impactType: json['impactType'] ?? '',
      impactValue: json['impactValue'] ?? 0,
      estimatedDamage: json['estimatedDamage'] ?? 0,
      estimatedLoss: json['estimatedLoss'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'belonging': belonging,
      'impactType': impactType,
      'impactValue': impactValue,
      'estimatedDamage': estimatedDamage,
      'estimatedLoss': estimatedLoss,
    };
  }
}

class ReportOfSighting {
  final List<InvolvedAnimal> involvedAnimals;

  ReportOfSighting({required this.involvedAnimals});

  factory ReportOfSighting.fromJson(Map<String, dynamic> json) {
    return ReportOfSighting(
      involvedAnimals: (json['involvedAnimals'] as List?)
              ?.map((e) => InvolvedAnimal.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {'involvedAnimals': involvedAnimals.map((e) => e.toJson()).toList()};
  }
}

class InteractionSpecies {
  final String id;
  final String name;
  final String commonName;
  final String category;
  final String advice;
  final String roleInNature;
  final String description;
  final String behaviour;

  InteractionSpecies({
    required this.id,
    required this.name,
    required this.commonName,
    this.category = '',
    this.advice = '',
    this.roleInNature = '',
    this.description = '',
    this.behaviour = '',
  });

  factory InteractionSpecies.fromJson(Map<String, dynamic> json) {
    return InteractionSpecies(
      id: json['ID'] ?? '',
      name: json['name'] ?? '',
      commonName: json['commonName'] ?? '',
      category: json['category'] ?? '',
      advice: json['advice'] ?? '',
      roleInNature: json['roleInNature'] ?? '',
      description: json['description'] ?? '',
      behaviour: json['behaviour'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'name': name,
      'commonName': commonName,
      'category': category,
      'advice': advice,
      'roleInNature': roleInNature,
      'description': description,
      'behaviour': behaviour,
    };
  }
}

class InteractionUser {
  final String id;
  final String name;

  InteractionUser({required this.id, required this.name});

  factory InteractionUser.fromJson(Map<String, dynamic> json) {
    return InteractionUser(id: json['ID'] ?? '', name: json['name'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'ID': id, 'name': name};
  }
}

class InteractionTypeInfo {
  final int id;
  final String name;
  final String description;

  InteractionTypeInfo({
    required this.id,
    required this.name,
    required this.description,
  });

  factory InteractionTypeInfo.fromJson(Map<String, dynamic> json) {
    return InteractionTypeInfo(
      id: json['ID'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'ID': id, 'name': name, 'description': description};
  }
}

class ExperimentInfo {
  final String id;
  final String name;
  final String description;
  final DateTime? start;
  final DateTime? end;
  final InteractionUser user;

  ExperimentInfo({
    required this.id,
    required this.name,
    this.description = '',
    this.start,
    this.end,
    required this.user,
  });

  factory ExperimentInfo.fromJson(Map<String, dynamic> json) {
    return ExperimentInfo(
      id: json['ID'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      start: json['start'] != null ? DateTime.tryParse(json['start']) : null,
      end: json['end'] != null ? DateTime.tryParse(json['end']) : null,
      user: InteractionUser.fromJson(json['user'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'name': name,
      'description': description,
      'start': start?.toIso8601String(),
      'end': end?.toIso8601String(),
      'user': user.toJson(),
    };
  }
}

class QuestionnaireInfo {
  final String id;
  final String name;
  final String identifier;
  final ExperimentInfo experiment;
  final InteractionTypeInfo interactionType;

  QuestionnaireInfo({
    required this.id,
    required this.name,
    required this.identifier,
    required this.experiment,
    required this.interactionType,
  });

  factory QuestionnaireInfo.fromJson(Map<String, dynamic> json) {
    return QuestionnaireInfo(
      id: json['ID'] ?? '',
      name: json['name'] ?? '',
      identifier: json['identifier'] ?? '',
      experiment: ExperimentInfo.fromJson(json['experiment'] ?? {}),
      interactionType: InteractionTypeInfo.fromJson(
        json['interactionType'] ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'name': name,
      'identifier': identifier,
      'experiment': experiment.toJson(),
      'interactionType': interactionType.toJson(),
    };
  }
}

class MyInteraction {
  final String id;
  final String description;
  final MyInteractionLocation location;
  final DateTime moment;
  final MyInteractionLocation place;
  final ReportOfCollision? reportOfCollision;
  final ReportOfDamage? reportOfDamage;
  final ReportOfSighting? reportOfSighting;
  final DateTime timestamp;
  final InteractionSpecies species;
  final InteractionUser user;
  final InteractionTypeInfo type;
  final QuestionnaireInfo? questionnaire;

  MyInteraction({
    required this.id,
    required this.description,
    required this.location,
    required this.moment,
    required this.place,
    this.reportOfCollision,
    this.reportOfDamage,
    this.reportOfSighting,
    required this.timestamp,
    required this.species,
    required this.user,
    required this.type,
    this.questionnaire,
  });

  factory MyInteraction.fromJson(Map<String, dynamic> json) {
    return MyInteraction(
      id: json['ID'] ?? '',
      description: json['description'] ?? '',
      location: MyInteractionLocation.fromJson(json['location'] ?? {}),
      moment: DateTime.parse(
        json['moment'] ?? DateTime.now().toIso8601String(),
      ),
      place: MyInteractionLocation.fromJson(json['place'] ?? {}),
      reportOfCollision: json['reportOfCollision'] != null
          ? ReportOfCollision.fromJson(json['reportOfCollision'])
          : null,
      reportOfDamage: json['reportOfDamage'] != null
          ? ReportOfDamage.fromJson(json['reportOfDamage'])
          : null,
      reportOfSighting: json['reportOfSighting'] != null
          ? ReportOfSighting.fromJson(json['reportOfSighting'])
          : null,
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      species: InteractionSpecies.fromJson(json['species'] ?? {}),
      user: InteractionUser.fromJson(json['user'] ?? {}),
      type: InteractionTypeInfo.fromJson(json['type'] ?? {}),
      questionnaire: json['questionnaire'] != null
          ? QuestionnaireInfo.fromJson(json['questionnaire'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'description': description,
      'location': location.toJson(),
      'moment': moment.toIso8601String(),
      'place': place.toJson(),
      if (reportOfCollision != null)
        'reportOfCollision': reportOfCollision!.toJson(),
      if (reportOfDamage != null) 'reportOfDamage': reportOfDamage!.toJson(),
      if (reportOfSighting != null)
        'reportOfSighting': reportOfSighting!.toJson(),
      'timestamp': timestamp.toIso8601String(),
      'species': species.toJson(),
      'user': user.toJson(),
      'type': type.toJson(),
      if (questionnaire != null) 'questionnaire': questionnaire!.toJson(),
    };
  }
}
