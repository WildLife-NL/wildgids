import 'package:wildgids/data_managers/api_client.dart';
import 'package:wildgids/data_managers/sighting_report_schema_loader.dart';

class SightingReportActivityOption {
  final String apiValue;
  final String labelNl;

  const SightingReportActivityOption(this.apiValue, this.labelNl);
}

class SightingReportActivityCatalog {
  SightingReportActivityCatalog._({
    required List<String> humanActivityValues,
    required List<String> perceivedAnimalActivityValues,
  })  : _humanActivityValues = List.unmodifiable(humanActivityValues),
        _perceivedAnimalActivityValues =
            List.unmodifiable(perceivedAnimalActivityValues);

  static SightingReportActivityCatalog? _cached;

  static const String otherApiValue = 'other...';
  static const String defaultHumanActivity = 'unknown';
  static const String defaultPerceivedAnimalActivity = 'unknown';

  static const Map<String, String> _perceivedAnimalLabelsNl = {
    'unknown': 'Onbekend',
    'walking': 'Lopen',
    'eating': 'Eten of drinken',
    'looking around': 'Rondkijken / omgeving scannen',
    'fleeing': '(Weg)rennen',
    'resting': 'Rusten',
    'other...': 'Anders, namelijk ...',
  };

  static const Map<String, String> _humanActivityLabelsNl = {
    'unknown': 'Onbekend',
    'walking': 'Lopen',
    'cycling': 'Fietsen',
    'mountain biking': 'Mountainbiken',
    'walking the dog': 'Hond uitlaten',
    'horse riding': 'Paardrijden',
    'photography': 'Fotograferen',
    'relaxing': 'Ontspannen',
    'other...': 'Anders, namelijk ...',
  };

  final List<String> _humanActivityValues;
  final List<String> _perceivedAnimalActivityValues;

  static SightingReportActivityCatalog get instance {
    final cached = _cached;
    if (cached == null) {
      throw StateError(
        'SightingReportActivityCatalog not loaded. Call load() first.',
      );
    }
    return cached;
  }

  static bool get isLoaded => _cached != null;

  static Future<SightingReportActivityCatalog> load(ApiClient apiClient) async {
    if (_cached != null) return _cached!;
    try {
      final schema = await SightingReportSchemaLoader(apiClient).fetch();
      _cached = SightingReportActivityCatalog._(
        humanActivityValues: schema.humanActivityValues,
        perceivedAnimalActivityValues: schema.perceivedAnimalActivityValues,
      );
    } catch (_) {
      _cached = SightingReportActivityCatalog._(
        humanActivityValues: _humanActivityLabelsNl.keys.toList(),
        perceivedAnimalActivityValues: _perceivedAnimalLabelsNl.keys.toList(),
      );
    }
    return _cached!;
  }

  static Future<void> preload(ApiClient apiClient) async {
    await load(apiClient);
  }

  static void loadFromSchemaForTest(SightingReportSchema schema) {
    _cached = SightingReportActivityCatalog._(
      humanActivityValues: schema.humanActivityValues,
      perceivedAnimalActivityValues: schema.perceivedAnimalActivityValues,
    );
  }

  List<SightingReportActivityOption> get humanActivities =>
      _humanActivityValues
          .map(
            (value) => SightingReportActivityOption(
              value,
              labelNlForHuman(value),
            ),
          )
          .toList();

  List<SightingReportActivityOption> get perceivedAnimalActivities =>
      _perceivedAnimalActivityValues
          .map(
            (value) => SightingReportActivityOption(
              value,
              labelNlForPerceivedAnimal(value),
            ),
          )
          .toList();

  static String labelNlForHuman(String apiValue) =>
      _humanActivityLabelsNl[apiValue] ?? _titleCase(apiValue);

  static String labelNlForPerceivedAnimal(String apiValue) =>
      _perceivedAnimalLabelsNl[apiValue] ?? _titleCase(apiValue);

  static bool isOtherHuman(String apiValue) => apiValue == otherApiValue;

  static bool isOtherPerceivedAnimal(String apiValue) => apiValue == otherApiValue;

  static String normalizeHuman(String? value) {
    final catalog = _cached;
    if (catalog == null || value == null || value.isEmpty) {
      return defaultHumanActivity;
    }
    if (catalog._humanActivityValues.contains(value)) return value;
    if (catalog._humanActivityValues.contains(defaultHumanActivity)) {
      return defaultHumanActivity;
    }
    return catalog._humanActivityValues.first;
  }

  static String normalizePerceivedAnimal(String? value) {
    final catalog = _cached;
    if (catalog == null || value == null || value.isEmpty) {
      return defaultPerceivedAnimalActivity;
    }
    if (catalog._perceivedAnimalActivityValues.contains(value)) return value;
    if (catalog._perceivedAnimalActivityValues
        .contains(defaultPerceivedAnimalActivity)) {
      return defaultPerceivedAnimalActivity;
    }
    return catalog._perceivedAnimalActivityValues.first;
  }

  static String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}

