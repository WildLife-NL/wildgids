import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:wildrapport/models/beta_models/belonging_damage_report_model.dart';

class BelongingDamageApiTransformer {
  static Map<String, dynamic> transformForApi(
    BelongingDamageReport report,
  ) {
    debugPrint('=== Starting DamageReport API Transform ===');
    debugPrint('Input Report: ${jsonEncode({
      "possesion": {
        "id": report.possesion.possesionID,
        "name": report.possesion.possesionName,
        "category": report.possesion.category,
      },
      "impactedAreaType": report.impactedAreaType,
      "impactedArea": report.impactedArea,
      "currentImpactDamages": report.currentImpactDamages,
      "estimatedTotalDamages": report.estimatedTotalDamages,
      "suspectedSpeciesID": report.suspectedSpeciesID,
      "userSelectedLocation": report.userSelectedLocation?.toJson(),
      "systemLocation": report.systemLocation?.toJson(),
      "userSelectedDateTime": report.userSelectedDateTime?.toIso8601String(),
      "systemDateTime": report.systemDateTime.toIso8601String(),
    })}');

    // --- validation before sending ---
    if (report.systemLocation == null) {
      throw StateError('System location is required for damage report');
    }
    if (report.userSelectedLocation == null) {
      throw StateError('User-selected location is required for damage report');
    }
    if (report.impactedAreaType.isEmpty) {
      throw StateError('impactType is required');
    }
    if (report.impactedArea == 0) {
      throw StateError('impactValue must be > 0');
    }

final belongingName = report.possesion.possesionName ?? '';

if (belongingName.trim().isEmpty) {
  throw StateError('belonging name is required');
}

    // --- final payload exactly how /interaction expects it for R5 ---
    final payload = {
      "description": report.description ?? "",
      "location": {
        "latitude": report.systemLocation!.latitude,
        "longitude": report.systemLocation!.longtitude,
      },
      "moment": report.systemDateTime.toUtc().toIso8601String(),
      // ^ backend examples use Z time like "2025-10-29T13:18:29.004944Z"

      "place": {
        "latitude": report.userSelectedLocation!.latitude,
        "longitude": report.userSelectedLocation!.longtitude,
      },

      "reportOfDamage": {
        // Backend expects a free text string for the belonging
        "belonging": belongingName,

        "estimatedDamage": report.currentImpactDamages,
        "estimatedLoss": report.estimatedTotalDamages,

        // API expects "square-meters" etc.
        "impactType": report.impactedAreaType,

        // API expects the numeric value (m2 or converted ha→m2)
        "impactValue": report.impactedArea,
      },

      // animal suspected of causing damage
      "speciesID": report.suspectedSpeciesID,

      // Interaction typeID 2 = Damage report / gewasschade
      "typeID": 2,
    };

    debugPrint('=== Final DamageReport API Payload ===');
    debugPrint(const JsonEncoder.withIndent('  ').convert(payload));
    debugPrint('======================================');

    return payload;
  }
}
