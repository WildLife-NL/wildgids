import 'package:wildgids/models/enums/animal_age.dart';
import 'package:wildgids/models/enums/animal_gender.dart';
import 'package:wildgids/models/enums/animal_condition.dart';
import 'package:wildgids/models/enums/animal_age_extensions.dart';
import 'package:wildgids/models/enums/animal_gender_extensions.dart';
import 'package:wildgids/models/enums/animal_condition_extensions.dart';

class ObservedAnimalEntry {
  final AnimalAge age;
  final AnimalGender gender;
  final AnimalCondition condition;
  final int count;

  ObservedAnimalEntry({
    required this.age,
    required this.gender,
    required this.condition,
    required this.count,
  });

  /// If `count` > 1, it will duplicate this map `count` times when building the payload.
  Map<String, dynamic> toBackendMapSingle() {
    return {
      'sex': gender.apiValue, // "male" | "female" | "other"
      'lifeStage':
          age.apiValue, // "infant" | "adolescent" | "adult" | "unknown"
      'condition':
          condition.apiValue, // "healthy" | "impaired" | "dead" | "other"
    };
  }
}

