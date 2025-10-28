import 'package:wildrapport/models/enums/animal_gender.dart';

extension AnimalGenderExtensions on AnimalGender {
  /// UI label (Dutch)
  String get label {
    switch (this) {
      case AnimalGender.mannelijk:
        return 'Mannelijk';
      case AnimalGender.vrouwelijk:
        return 'Vrouwelijk';
      case AnimalGender.onbekend:
        return 'Onbekend';
    }
  }

  /// Backend value for `sex`
  String get apiValue {
    switch (this) {
      case AnimalGender.mannelijk:
        return 'male';
      case AnimalGender.vrouwelijk:
        return 'female';
      case AnimalGender.onbekend:
        return 'other'; // backend does NOT have "unknown", it uses "other"
    }
  }
}
