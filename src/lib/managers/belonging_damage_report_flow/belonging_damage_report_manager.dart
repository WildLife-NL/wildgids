import 'package:flutter/material.dart';
import 'package:wildgids/interfaces/data_apis/belonging_api_interface.dart';
import 'package:wildgids/interfaces/data_apis/interaction_api_interface.dart';
import 'package:wildgids/interfaces/reporting/interaction_interface.dart';
import 'package:wildgids/interfaces/reporting/belonging_damage_report_interface.dart';
import 'package:wildgids/models/beta_models/belonging_model.dart';
import 'package:wildgids/models/beta_models/interaction_response_model.dart';
import 'package:wildgids/models/beta_models/belonging_damage_report_model.dart';
import 'package:wildgids/models/beta_models/report_location_model.dart';
// Crop damage flow discontinued: no interaction types used here anymore
import 'package:wildgids/providers/map_provider.dart';
import 'package:wildgids/providers/belonging_damage_report_provider.dart';

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
    final List<Map<String, String>> allBelongings = [
      {
        "ID": "61726f48-066b-46b6-84cd-6fee993e4c74",
        "name": "Bieten",
        "category": "Gewassen",
      },
      {
        "ID": "086001b5-126b-44ba-bc81-ab2f9416ab58",
        "name": "Bloementeelt",
        "category": "Gewassen",
      },
      {
        "ID": "0bf4e74c-b196-436a-9166-8fa4d9dd5db9",
        "name": "Boomteelt",
        "category": "Gewassen",
      },
      {
        "ID": "db9c7716-ec68-499c-9528-a3ab58607b3c",
        "name": "Granen",
        "category": "Gewassen",
      },
      {
        "ID": "5013a551-21d9-4874-af7e-b60800329e91",
        "name": "Grasvelden",
        "category": "Gewassen",
      },
      {
        "ID": "aef8950b-c7aa-42c6-848e-1d72d0636a64",
        "name": "MaÃ¯s",
        "category": "Gewassen",
      },
      {
        "ID": "0dc5864b-6fd7-4703-a41b-7e45a0c4b558",
        "name": "Tuinbouw",
        "category": "Gewassen",
      },
    ];
    final response = await belongingAPI.getAllBelongings();

    if (response.isEmpty) {
      debugPrint("$redLog EEEEEEEEEEEE");
    }

    //printing where the value came from
    response.isEmpty
        ? debugPrint(
          "$yellowLog [BelongingDamageReportManager]: Using fallback values!",
        )
        : debugPrint(
          "$greenLog [BelongingDamageReportManager]: Using backend values!",
        );

    belongings =
        (response.isEmpty) ? allBelongings : _mapToMapString3x(response);
  }

  // List<Belonging> _mapToListOfBelonging(List<Map<String, String>> maps) {
  //   List<Belonging> mappedBelongings = [];
  //   for(Map<String, String> map in maps){
  //     mappedBelongings.add(
  //       Belonging(
  //         ID: map['ID'] ?? '',
  //         name: map['name'] ?? '',
  //         category: map['category'] ?? '',)
  //     );
  //   }
  //   return mappedBelongings;
  // }
  //Higly suggest refactoring the flow to just use List<Belonging> everywhere
  List<Map<String, String>> _mapToMapString3x(List<Belonging> allBelongings) {
    List<Map<String, String>> resultMap = [];
    for (Belonging belonging in allBelongings) {
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
    // Flow removed: return no widgets
    return [];
  }

  @override
  Future<InteractionResponse?> postInteraction() async {
    // Flow removed: do not post any interactions
    debugPrint('[BelongingDamageReportManager] Flow removed; no interaction posted.');
    return null;
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
    // Flow removed: do not build any report
    return null;
  }

  // String _normalize(String input) {
  //   return input
  //       .toLowerCase()
  //       .replaceAll('Ã¯', 'i')
  //       .replaceAll('Ã­', 'i')
  //       .replaceAll('Ã¬', 'i')
  //       .replaceAll('Ã®', 'i')
  //       .replaceAll('Ã«', 'e')
  //       .replaceAll('Ã©', 'e')
  //       .replaceAll('Ã¨', 'e')
  //       .replaceAll('Ãª', 'e')
  //       .replaceAll('Ã¡', 'a')
  //       .replaceAll('Ã ', 'a')
  //       .replaceAll('Ã¤', 'a')
  //       .replaceAll('Ã¢', 'a')
  //       .replaceAll('Ã³', 'o')
  //       .replaceAll('Ã²', 'o')
  //       .replaceAll('Ã¶', 'o')
  //       .replaceAll('Ã´', 'o')
  //       .replaceAll('Ã¼', 'u')
  //       .replaceAll('Ãº', 'u')
  //       .replaceAll('Ã¹', 'u')
  //       .replaceAll('Ã»', 'u')
  //       .trim();
  // }

  // -------------------------------
  // map the user's picked crop name (UI text) -> backend Possesion
  // -------------------------------
  // Possesion? _getCorrectPossesion(String pickedName) {
  //   final normalizedPicked = _normalize(pickedName);

  //   // try to find exact match after normalization
  //   for (final belonging in _mapToListOfBelonging(belongings)) {
  //     final normalizedBelongingName = _normalize(belonging.name);
  //     if (normalizedBelongingName == normalizedPicked) {
  //       return Possesion(
  //         possesionID: belonging.ID ?? '',
  //         possesionName: belonging.name,
  //         category: belonging.category,
  //       );
  //     }
  //   }

  //   // if we didn't find a normalized match, log + return null
  //   debugPrint(
  //     "$yellowLog[BelongingDamageReportManager] No match for '$pickedName' in belongings list$redLog",
  //   );
  //   return null;
  // }

  // void _ensureBelongingsLoaded() {
  // if (belongings.isNotEmpty) return;

  // // fallback list (same as in init())
  // belongings = [
  //   {
  //     "ID": "61726f48-066b-46b6-84cd-6fee993e4c74",
  //     "name": "Bieten",
  //     "category": "Gewassen"
  //   },
  //   {
  //     "ID": "086001b5-126b-44ba-bc81-ab2f9416ab58",
  //     "name": "Bloementeelt",
  //     "category": "Gewassen"
  //   },
  //   {
  //     "ID": "0bf4e74c-b196-436a-9166-8fa4d9dd5db9",
  //     "name": "Boomteelt",
  //     "category": "Gewassen"
  //   },
  //   {
  //     "ID": "db9c7716-ec68-499c-9528-a3ab58607b3c",
  //     "name": "Granen",
  //     "category": "Gewassen"
  //   },
  //   {
  //     "ID": "5013a551-21d9-4874-af7e-b60800329e91",
  //     "name": "Grasvelden",
  //     "category": "Gewassen"
  //   },
  //   {
  //     "ID": "aef8950b-c7aa-42c6-848e-1d72d0636a64",
  //     "name": "MaÃ¯s",
  //     "category": "Gewassen"
  //   },
  //   {
  //     "ID": "0dc5864b-6fd7-4703-a41b-7e45a0c4b558",
  //     "name": "Tuinbouw",
  //     "category": "Gewassen"
  //   }
  // ];

  // debugPrint('[BelongingDamageReportManager] ðŸ”„ belongings loaded via fallback (${belongings.length} items)');
  // }
}

