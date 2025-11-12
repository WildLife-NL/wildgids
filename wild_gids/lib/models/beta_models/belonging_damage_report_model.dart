import 'package:wildrapport/interfaces/reporting/possesion_report_fields.dart';
import 'package:wildrapport/interfaces/reporting/reportable_interface.dart';
import 'package:wildrapport/models/beta_models/possesion_model.dart';
import 'package:wildrapport/models/beta_models/report_location_model.dart';

class BelongingDamageReport implements Reportable, PossesionReportFields {
  final String? possesionDamageReportID;

  @override
  final Possesion possesion; // what got damaged (crop etc.)

  @override
  final String impactedAreaType; // e.g. "square-meters"

  @override
  final double impactedArea; // numeric value (already in correct unit)

  @override
  final double currentImpactDamages; // estimatedDamage €

  @override
  final double estimatedTotalDamages; // estimatedLoss €

  @override
  final String? description;

  @override
  final String? suspectedSpeciesID; // speciesID that caused damage

  @override
  final ReportLocation? userSelectedLocation; // "place" in payload

  @override
  final ReportLocation? systemLocation; // "location" in payload

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

  // ⬇⬇⬇ THIS IS THE IMPORTANT PART ⬇⬇⬇
  // We now return EXACTLY what /interaction expects for a damage report (typeID: 2)
  @override
  Map<String, dynamic> toJson() {
    // Basic validation (keeps us from sending garbage to backend)
    if (systemLocation == null) {
      throw StateError('System location is required for damage report');
    }
    if (userSelectedLocation == null) {
      throw StateError('User-selected location is required for damage report');
    }
    if (impactedAreaType.isEmpty) {
      throw StateError('impactType is required');
    }
    if (impactedArea == 0) {
      throw StateError('impactValue must be > 0');
    }

    final String belongingName = possesion.possesionName ?? '';
    if (belongingName.trim().isEmpty) {
      throw StateError('belonging (what was damaged) is required');
    }

    return {
      "description": description ?? "",
      "location": {
        "latitude": systemLocation!.latitude,
        "longitude": systemLocation!.longtitude,
      },
      // API examples use UTC ISO8601 with Z, so send UTC
      "moment": systemDateTime.toUtc().toIso8601String(),
      "place": {
        "latitude": userSelectedLocation!.latitude,
        "longitude": userSelectedLocation!.longtitude,
      },
      "reportOfDamage": {
        // VERY IMPORTANT: backend wants a STRING here, not an object
        "belonging": belongingName, // e.g. "Maïs"

        "estimatedDamage": currentImpactDamages,      // € now
        "estimatedLoss": estimatedTotalDamages,       // € future
        "impactType": impactedAreaType,               // "square-meters"
        "impactValue": impactedArea,                  // numeric area
      },
      "speciesID": suspectedSpeciesID,
      "typeID": 2, // 2 = gewasschade / damage report
    };
  }

  // You can keep fromJson if you still need to deserialize local/offline copies.
  // This is for app-side storage, NOT the /interaction response.
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
        userSelectedLocation: json["userSelectedLocation"] != null
            ? ReportLocation.fromJson(json["userSelectedLocation"])
            : null,
        systemLocation: json["systemLocation"] != null
            ? ReportLocation.fromJson(json["systemLocation"])
            : null,
        userSelectedDateTime: json["userSelectedDateTime"] != null
            ? DateTime.parse(json["userSelectedDateTime"])
            : null,
        systemDateTime: DateTime.parse(json["systemDateTime"]),
      );
}
