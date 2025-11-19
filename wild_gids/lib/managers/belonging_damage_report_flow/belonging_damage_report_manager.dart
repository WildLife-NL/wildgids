import 'package:flutter/material.dart';
import 'package:wildrapport/interfaces/data_apis/belonging_api_interface.dart';
import 'package:wildrapport/interfaces/data_apis/interaction_api_interface.dart';
import 'package:wildrapport/interfaces/reporting/interaction_interface.dart';
import 'package:wildrapport/interfaces/reporting/belonging_damage_report_interface.dart';
import 'package:wildrapport/models/beta_models/belonging_model.dart';
import 'package:wildrapport/models/beta_models/interaction_response_model.dart';
import 'package:wildrapport/models/beta_models/belonging_damage_report_model.dart';
import 'package:wildrapport/models/beta_models/possesion_model.dart';
import 'package:wildrapport/models/beta_models/report_location_model.dart';
import 'package:wildrapport/models/enums/interaction_type.dart';
import 'package:wildrapport/providers/map_provider.dart';
import 'package:wildrapport/providers/belonging_damage_report_provider.dart';
import 'package:wildrapport/widgets/belonging/belonging_crops_details.dart';
import 'package:wildrapport/widgets/belonging/suspected_animal.dart';

class BelongingDamageReportManager implements BelongingDamageReportInterface {
  final InteractionApiInterface interactionAPI;
  final BelongingApiInterface belongingAPI;
  final BelongingDamageReportProvider formProvider;
  final MapProvider mapProvider;
  final InteractionInterface interactionManager;

  List<Map<String, String>> belongings = [];

  BelongingDamageReportManager({
    required this.interactionAPI,
    required this.belongingAPI,
    required this.formProvider,
    required this.mapProvider,
    required this.interactionManager,
  });

  final greenLog = '\x1B[32m';
  final redLog = '\x1B[31m';
  final yellowLog = '\x1B[93m';

  void init() async {
    debugPrint("[BelongingDamageReportManager]: Initializing!");
    final List<Map<String, String>> allBelongings = 
      [
        {
          "ID": "61726f48-066b-46b6-84cd-6fee993e4c74",
          "name": "Bieten",
          "category": "Gewassen"
        },
        {
          "ID": "086001b5-126b-44ba-bc81-ab2f9416ab58",
          "name": "Bloementeelt",
          "category": "Gewassen"
        },
        {
          "ID": "0bf4e74c-b196-436a-9166-8fa4d9dd5db9",
          "name": "Boomteelt",
          "category": "Gewassen"
        },
        {
          "ID": "db9c7716-ec68-499c-9528-a3ab58607b3c",
          "name": "Granen",
          "category": "Gewassen"
        },
        {
          "ID": "5013a551-21d9-4874-af7e-b60800329e91",
          "name": "Grasvelden",
          "category": "Gewassen"
        },
        {
          "ID": "aef8950b-c7aa-42c6-848e-1d72d0636a64",
          "name": "Maïs",
          "category": "Gewassen"
        },
        {
          "ID": "0dc5864b-6fd7-4703-a41b-7e45a0c4b558",
          "name": "Tuinbouw",
          "category": "Gewassen"
        }
      ];
      final response = await belongingAPI.getAllBelongings();
      
      if(response.isEmpty) {debugPrint("$redLog EEEEEEEEEEEE");}

      //printing where the value came from
      response.isEmpty 
        ? debugPrint("$yellowLog [BelongingDamageReportManager]: Using fallback values!") 
        : debugPrint("$greenLog [BelongingDamageReportManager]: Using backend values!");

      belongings = (response.isEmpty)
          ? allBelongings
          : _mapToMapString3x(response);
  }

  List<Belonging> _mapToListOfBelonging(List<Map<String, String>> maps) {
    List<Belonging> mappedBelongings = [];
    for(Map<String, String> map in maps){
      mappedBelongings.add(
        Belonging(      
          ID: map['ID'] ?? '',
          name: map['name'] ?? '',
          category: map['category'] ?? '',)
      );
    }
    return mappedBelongings;
  }
  //Higly suggest refactoring the flow to just use List<Belonging> everywhere
  List<Map<String, String>> _mapToMapString3x(List<Belonging> allBelongings){
    List<Map<String, String>> resultMap = [];
    for(Belonging belonging in allBelongings){
      resultMap.add({
        'ID': belonging.ID ?? '',
        'name': belonging.name,
        'category': belonging.category,
      });
    }
    return resultMap;
  }

  @override
  List<dynamic> buildPossesionWidgetList() {
    return [BelongingCropsDetails(), SuspectedAnimal()];
  }

@override
Future<InteractionResponse?> postInteraction() async {
  final BelongingDamageReport? report = buildBelongingReport();

  if (report == null) {
    debugPrint('[BelongingDamageReportManager] buildBelongingReport() returned null, aborting send');
    return null;
  }

  InteractionResponse? interactionResponseModel;
  try {
    interactionResponseModel = await interactionManager.postInteraction(
      report, // <- this is now fine because toJson() matches API
      InteractionType.gewasschade,
    );
  } catch (e, stackTrace) {
    debugPrint('[BelongingDamageReportManager] Error posting interaction: $e');
    debugPrint(stackTrace.toString());
    interactionResponseModel = null;
  }

  if (interactionResponseModel != null) {
    debugPrint('[BelongingDamageReportManager] ✅ Interaction posted successfully.');
    // you can keep your questionnaire logging here
    formProvider.clearStateOfValues();
  } else {
    debugPrint('[BelongingDamageReportManager] ❌ No response (probably offline).');
    // keep provider so user can retry
  }

  return interactionResponseModel;
}




  @override
  void updateSystemLocation(ReportLocation value) {
    formProvider.setSystemLocation(value);
  }

  @override
  void updateUserLocation(ReportLocation value) {
    formProvider.setUserLocation(value);
  }

@override
void updateCurrentDamage(double value) {
  formProvider.setEstimatedDamage(value);
}

  @override
  void updateDescription(String value) {
    formProvider.setDescription(value);
  }

@override
void updateExpectedDamage(double value) {
  formProvider.setEstimatedLoss(value);
}

@override
void updateImpactedArea(double value) {
  // UI already restricts to integer text; we still guard for > 0
  if (value <= 0) return;
  formProvider.setImpactedArea(value);
}

@override
void updateImpactedAreaType(String value) {
  // value is 'vierkante meters' or 'units'
  formProvider.setImpactedAreaType(value);
}

  @override
  void updateImpactedCrop(String value) {
    formProvider.setImpactedCrop(value);
  }

  @override
  void updateSuspectedAnimal(String value) {
    formProvider.setSuspectedAnimal(value);
  }

@override
BelongingDamageReport? buildBelongingReport() {
  debugPrint("✅ buildBelongingReport called");
  debugPrint("✅ formProvider.impactedCrop: '${formProvider.impactedCrop}'");
  debugPrint("✅ formProvider.impactedArea: ${formProvider.impactedArea}");
  debugPrint("✅ formProvider.impactedAreaType: '${formProvider.impactedAreaType}'");

  try {
    // --- validate minimal required fields ---
    if (formProvider.impactedCrop.isEmpty) {
      throw Exception("Impacted crop is empty");
    }
    if (formProvider.impactedArea == null) {
      throw Exception("Impacted area is empty");
    }

    // ✅ Use the free text crop name directly as belonging
    final Possesion pos = Possesion(
      possesionID: null,
      possesionName: formProvider.impactedCrop,
      category: null,
    );
    debugPrint("✅ Created Possesion with name: '${pos.possesionName}'");

    // locations (fallbacks if missing)
    final systemReportLocation =
        formProvider.systemLocation ??
        ReportLocation(latitude: 20.0, longtitude: 20.0);

    final userReportLocation =
        formProvider.userLocation ??
        ReportLocation(latitude: 20.0, longtitude: 20.0);

    // ✅ Convert UI unit -> API unit using provider helpers
    final String impactType = formProvider.apiImpactType; // "square-meters" | "units"
    final int? impactValueInt = formProvider.apiImpactValueOrNull; // already m²/units as INT
    if (impactValueInt == null || impactValueInt < 1) {
      throw Exception("Invalid impact value");
    }

    // Build the report model (toJson will round everything correctly as ints)
    final report = BelongingDamageReport(
      possesion: pos,
      impactedAreaType: impactType,                      // e.g. "square-meters"
      impactedArea: impactValueInt.toDouble(),           // keep double in model; toJson rounds
      currentImpactDamages: formProvider.estimatedDamage,
      estimatedTotalDamages: formProvider.estimatedLoss,
      description: formProvider.description,
      suspectedSpeciesID: formProvider.suspectedSpeciesID,
      userSelectedDateTime: DateTime.now(),
      systemDateTime: DateTime.now(),
      systemLocation: systemReportLocation,
      userSelectedLocation: userReportLocation,
    );

    debugPrint("✅ Report created: $report");
    return report;
  } catch (e, stackTrace) {
    debugPrint("❌ Exception in buildBelongingReport: $e");
    debugPrint("🔍 Stack trace: $stackTrace");
    rethrow;
  }
}


  String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll('ï', 'i')
        .replaceAll('í', 'i')
        .replaceAll('ì', 'i')
        .replaceAll('î', 'i')
        .replaceAll('ë', 'e')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ó', 'o')
        .replaceAll('ò', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('ü', 'u')
        .replaceAll('ú', 'u')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .trim();
  }

  // -------------------------------
  // map the user's picked crop name (UI text) -> backend Possesion
  // -------------------------------
  Possesion? _getCorrectPossesion(String pickedName) {
    final normalizedPicked = _normalize(pickedName);

    // try to find exact match after normalization
    for (final belonging in _mapToListOfBelonging(belongings)) {
      final normalizedBelongingName = _normalize(belonging.name);
      if (normalizedBelongingName == normalizedPicked) {
        return Possesion(
          possesionID: belonging.ID ?? '',
          possesionName: belonging.name,
          category: belonging.category,
        );
      }
    }

    // if we didn't find a normalized match, log + return null
    debugPrint(
      "$yellowLog[BelongingDamageReportManager] No match for '$pickedName' in belongings list$redLog",
    );
    return null;
  }


  void _ensureBelongingsLoaded() {
  if (belongings.isNotEmpty) return;

  // fallback list (same as in init())
  belongings = [
    {
      "ID": "61726f48-066b-46b6-84cd-6fee993e4c74",
      "name": "Bieten",
      "category": "Gewassen"
    },
    {
      "ID": "086001b5-126b-44ba-bc81-ab2f9416ab58",
      "name": "Bloementeelt",
      "category": "Gewassen"
    },
    {
      "ID": "0bf4e74c-b196-436a-9166-8fa4d9dd5db9",
      "name": "Boomteelt",
      "category": "Gewassen"
    },
    {
      "ID": "db9c7716-ec68-499c-9528-a3ab58607b3c",
      "name": "Granen",
      "category": "Gewassen"
    },
    {
      "ID": "5013a551-21d9-4874-af7e-b60800329e91",
      "name": "Grasvelden",
      "category": "Gewassen"
    },
    {
      "ID": "aef8950b-c7aa-42c6-848e-1d72d0636a64",
      "name": "Maïs",
      "category": "Gewassen"
    },
    {
      "ID": "0dc5864b-6fd7-4703-a41b-7e45a0c4b558",
      "name": "Tuinbouw",
      "category": "Gewassen"
    }
  ];

  debugPrint('[BelongingDamageReportManager] 🔄 belongings loaded via fallback (${belongings.length} items)');
}

}
