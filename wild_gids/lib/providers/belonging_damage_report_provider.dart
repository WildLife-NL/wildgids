import 'package:flutter/material.dart';
import 'package:wildrapport/models/beta_models/report_location_model.dart';

class BelongingDamageReportProvider extends ChangeNotifier {
  String impactedCrop = '';
  double currentDamage = 0;
  double expectedDamage = 0;
  String impactedAreaType = 'vierkante meters'; // Default to m²
  double? impactedArea;
  String description = '';
  String? suspectedSpeciesID;
  final greenLog = '\x1B[32m';
  bool hasErrorImpactedCrop = false;
  bool hasErrorImpactedAreaType = false;
  bool hasErrorImpactedArea = false;
  ReportLocation? systemLocation;
  ReportLocation? userLocation;
  bool expanded = false;
  String? inputErrorImpactArea;
  String? selectedText = 'm²'; // Default display text

    // ── Backend-aligned aliases (safe, incremental) ────────────────────────────
  // Use these names everywhere new code touches the provider.
  double get estimatedDamage => currentDamage;
  double get estimatedLoss => expectedDamage;

  void setEstimatedDamage(double value) {
    currentDamage = value;
    notifyListeners();
  }

  void setEstimatedLoss(double value) {
    expectedDamage = value;
    notifyListeners();
  }

  @Deprecated('Use setEstimatedDamage')
  void setCurrentDamage(double value) => setEstimatedDamage(value);

  @Deprecated('Use setEstimatedLoss')
  void setExpectedDamage(double value) => setEstimatedLoss(value);

  // ── API mapping helpers (UI -> API) ────────────────────────────────────────
  // API wants impactType in {"square-meters","units"} and impactValue as int >= 1 (m² or units).
  String get apiImpactType =>
      impactedAreaType == 'units' ? 'units' : 'square-meters';

  int? get apiImpactValueOrNull {
    if (impactedArea == null) return null;

    // Convert hectares to m²; leave m² as-is; (future) 'units' unchanged.
    double raw = impactedArea!;
    switch (impactedAreaType) {
      case 'hectare':
        raw = raw * 10000.0; // ha -> m²
        break;
      case 'vierkante meters':
      case 'units':
      default:
        // raw unchanged
        break;
    }

    final int rounded = raw.round();
    return (rounded < 1) ? 1 : rounded;
  }

  bool get isReadyForSubmit =>
      impactedCrop.isNotEmpty && apiImpactValueOrNull != null;

  void updateSelectedText(String value) {
    selectedText = value;
  }

  void updateExpanded(bool value) {
    debugPrint("updateExpanded: $value");
    expanded = value;
    notifyListeners();
  }

  void updateInputErrorImpactArea(String value) {
    inputErrorImpactArea = value;
    notifyListeners();
  }

  void resetInputErrorImpactArea() {
    inputErrorImpactArea = null;
    notifyListeners();
  }

  void setImpactedCrop(String value) {
    impactedCrop = value;
    notifyListeners();
  }

  void setImpactedAreaType(String value) {
    impactedAreaType = value;
    notifyListeners();
  }

  void setImpactedArea(double value) {
    impactedArea = value;
    notifyListeners();
  }

  void setDescription(String value) {
    description = value;
    notifyListeners();
  }

  void setSuspectedAnimal(String value) {
    suspectedSpeciesID = value;
    notifyListeners();
  }

  void setSystemLocation(ReportLocation value) {
    systemLocation = value;
    notifyListeners();
  }

  void setUserLocation(ReportLocation value) {
    userLocation = value;
    notifyListeners();
  }

  void setHasErrorImpactedArea(bool value) {
    hasErrorImpactedArea = value;
    notifyListeners();
  }

  void resetImpactedArea() {
    impactedArea = null;
  }

  void setErrorState(String field, bool hasError) {
    if (field == 'impactedCrop') {
      hasErrorImpactedCrop = hasError;
    } else if (field == 'impactedAreaType') {
      hasErrorImpactedAreaType = hasError;
    } else if (field == 'impactedArea') {
      hasErrorImpactedArea = hasError;
    }
    notifyListeners();
  }

  void clearStateOfValues() {
    debugPrint("$greenLog[PossesionDamageReportProvider]: Clearing Values!");
    impactedCrop = '';
    currentDamage = 0;
    expectedDamage = 0;
    impactedAreaType = '';
    impactedArea = null;
    description = '';
    hasErrorImpactedCrop = false;
    hasErrorImpactedAreaType = false;
    hasErrorImpactedArea = false;
    selectedText = null;
    resetInputErrorImpactArea();
    notifyListeners();
  }

  void resetErrors() {
    hasErrorImpactedCrop = false;
    hasErrorImpactedAreaType = false;
    hasErrorImpactedArea = false;
    notifyListeners();
  }
}
