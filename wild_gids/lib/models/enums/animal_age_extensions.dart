import 'package:wildrapport/models/enums/animal_age.dart';

extension AnimalAgeExtensions on AnimalAge {
  /// Label to show in the UI (Dutch)
  String get label {
    switch (this) {
      case AnimalAge.pasGeboren:
        return 'Pas geboren'; // was "<6 maanden"
      case AnimalAge.onvolwassen:
        return 'Onvolwassen';
      case AnimalAge.volwassen:
        return 'Volwassen';
      case AnimalAge.onbekend:
        return 'Onbekend';
    }
  }

  /// Exact string backend expects in lifeStage
  String get apiValue {
    switch (this) {
      case AnimalAge.pasGeboren:
        return 'infant';
      case AnimalAge.onvolwassen:
        return 'adolescent';
      case AnimalAge.volwassen:
        return 'adult';
      case AnimalAge.onbekend:
        return 'unknown';
    }
  }

  /// If backend sends us strings, map them back to enum
  static AnimalAge fromApiString(String? raw) {
    if (raw == null) return AnimalAge.onbekend;

    final s = raw.trim().toLowerCase();
    const map = {
      // backend → enum
      'infant': AnimalAge.pasGeboren,
      'adolescent': AnimalAge.onvolwassen,
      'adult': AnimalAge.volwassen,
      'unknown': AnimalAge.onbekend,

      // old app values / shorthand
      '<6 months': AnimalAge.pasGeboren,
      '<6 maanden': AnimalAge.pasGeboren,
      'pas geboren': AnimalAge.pasGeboren,
      'recently born': AnimalAge.pasGeboren,
      'recently_born': AnimalAge.pasGeboren,
      'kalf': AnimalAge.pasGeboren,
      'onvolwassen': AnimalAge.onvolwassen,
      'young': AnimalAge.onvolwassen,
      'juvenile': AnimalAge.onvolwassen,
      'volwassen': AnimalAge.volwassen,
      'onbekend': AnimalAge.onbekend,
    };
    return map[s] ?? AnimalAge.onbekend;
  }
}
