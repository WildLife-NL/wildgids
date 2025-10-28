import 'package:flutter/material.dart';
import 'package:wildrapport/models/beta_models/report_location_model.dart';

class BelongingDamageReportProvider extends ChangeNotifier {
  String impactedCrop = '';
  double currentDamage = 0;
  double expectedDamage = 0;
  String impactedAreaType = '';
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
  String? selectedText;

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

  void setCurrentDamage(double value) {
    currentDamage = value;
    notifyListeners();
  }

  void setExpectedDamage(double value) {
    expectedDamage = value;
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
