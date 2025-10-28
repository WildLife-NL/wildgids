import 'package:wildrapport/interfaces/reporting/possesion_report_fields.dart';
import 'package:wildrapport/interfaces/reporting/reportable_interface.dart';
import 'package:wildrapport/models/beta_models/possesion_model.dart';
import 'package:wildrapport/models/beta_models/report_location_model.dart';

class BelongingDamageReport implements Reportable, PossesionReportFields {
  final String? possesionDamageReportID;
  @override
  final Possesion possesion;
  @override
  final String impactedAreaType;
  @override
  final double impactedArea;
  @override
  final double currentImpactDamages;
  @override
  final double estimatedTotalDamages;
  @override
  final String? description;
  @override
  final String? suspectedSpeciesID;
  @override
  final ReportLocation? userSelectedLocation;
  @override
  final ReportLocation? systemLocation;
  @override
  final DateTime? userSelectedDateTime;
  @override
  final DateTime systemDateTime;

  BelongingDamageReport({
    this.possesionDamageReportID,
    required this.possesion,
    required this.impactedAreaType,
    required this.impactedArea,
    required this.currentImpactDamages,
    required this.estimatedTotalDamages,
    this.description,
    this.suspectedSpeciesID,
    this.userSelectedLocation,
    this.systemLocation,
    this.userSelectedDateTime,
    required this.systemDateTime,
  });
  @override
  Map<String, dynamic> toJson() => {
    "possesionDamageReportID": possesionDamageReportID,
    "belonging": {
      "ID": possesion.possesionID,
      "name": possesion.possesionName,
      "category": possesion.category,
    },
    "impactType": impactedAreaType,
    "impactValue": impactedArea,
    "estimatedDamage": currentImpactDamages,
    "estimatedLoss": estimatedTotalDamages,
    "description": description,
    "suspectedAnimalID": suspectedSpeciesID,
    "userSelectedLocation": userSelectedLocation?.toJson(),
    "systemLocation": systemLocation?.toJson(),
    "userSelectedDateTime": userSelectedDateTime?.toIso8601String(),
    "systemDateTime": systemDateTime.toIso8601String(),
  };

  factory BelongingDamageReport.fromJson(Map<String, dynamic> json) =>
      BelongingDamageReport(
        possesionDamageReportID: json["possesionDamageReportID"],
        possesion: Possesion.fromJson(json["belonging"]),
        impactedAreaType: json["impactType"],
        impactedArea: (json["impactValue"] as num).toDouble(),
        currentImpactDamages: (json["estimatedDamage"] as num).toDouble(),
        estimatedTotalDamages: (json["estimatedLoss"] as num).toDouble(),
        description: json["description"],
        suspectedSpeciesID: json["suspectedAnimalID"],
        userSelectedLocation:
            json["userSelectedLocation"] != null
                ? ReportLocation.fromJson(json["userSelectedLocation"])
                : null,
        systemLocation:
            json["systemLocation"] != null
                ? ReportLocation.fromJson(json["systemLocation"])
                : null,
        userSelectedDateTime:
            json["userSelectedDateTime"] != null
                ? DateTime.parse(json["userSelectedDateTime"])
                : null,
        systemDateTime: DateTime.parse(json["systemDateTime"]),
      );
}

