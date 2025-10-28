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
  //⌄ This needs to be refactored to use the new Belongings in the new API

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
    BelongingDamageReport? belongingDamageReport = buildBelongingReport();
    InteractionResponse? interactionResponseModel;
    if(belongingDamageReport != null){
      interactionResponseModel =
        await interactionManager.postInteraction(
          belongingDamageReport,
          InteractionType.gewasschade,
        );
      }
    if (interactionResponseModel != null) {
      debugPrint("$greenLog${interactionResponseModel.questionnaire.name}");

      // Add null check before accessing questions
      if (interactionResponseModel.questionnaire.questions != null &&
          interactionResponseModel.questionnaire.questions!.isNotEmpty) {
        debugPrint(
          "$greenLog${interactionResponseModel.questionnaire.questions![0].description}",
        );
      } else {
        debugPrint("${greenLog}No questions available in questionnaire");
      }

      //Clearing the provider of it's value
      formProvider.clearStateOfValues();

      return interactionResponseModel;
    } else {
      return null;
    }
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
    formProvider.setCurrentDamage(value);
  }

  @override
  void updateDescription(String value) {
    formProvider.setDescription(value);
  }

  @override
  void updateExpectedDamage(double value) {
    formProvider.setExpectedDamage(value);
  }

  @override
  void updateImpactedArea(double value) {
    try {
      if (formProvider.impactedAreaType == "hectare") {
        debugPrint("$greenLog impactArea selected is Hectare");
        formProvider.setImpactedArea(value);
      } else if (formProvider.impactedAreaType == "vierkante meters") {
        debugPrint("$greenLog impactArea selected is Vierkante Meters");
        formProvider.setImpactedArea(value);
      } else {
        throw Exception(
          "$redLog Impacted Area Type of: ${formProvider.impactedAreaType} Isn't Valid!",
        );
      }
    } catch (e, stackTrace) {
      debugPrint("$redLog Something went wrong:");
      debugPrint("$redLog Message: ${e.toString()}");
      debugPrint("$redLog Stacktrace: $stackTrace");
    }
  }

  @override
  void updateImpactedAreaType(String value) {
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

  //we only use vierkante meters and unit, unit as in number of sheep in the future
  String getCorrectImpactAreaType() {
    return "square-meters";
  }

  String getCorrectImpactArea() {
    try {
      switch (formProvider.impactedAreaType) {
        case "vierkante meters":
          return formProvider.impactedArea.toString();
        case "hectare":
          return (formProvider.impactedArea! * 10000).toString();

        default:
          throw Exception("impactedAreaType is invalid!");
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  BelongingDamageReport? buildBelongingReport() {
    debugPrint("✅ buildReportTesting called");
    try {
      // Log provider state
      debugPrint(
        "📍 formProvider location state: selectedPosition=${formProvider.userLocation}, currentPosition=${formProvider.systemLocation}",
      );
      debugPrint(
        "📋 formProvider state: "
        "impactedCrop=${formProvider.impactedCrop}, "
        "impactedAreaType=$getCorrectImpactAreaType()"
        "impactedArea=${getCorrectImpactArea()}, "
        "currentDamage=${formProvider.currentDamage}, "
        "expectedDamage=${formProvider.expectedDamage}, "
        "description=${formProvider.description}, "
        "suspectedSpeciesID=${formProvider.suspectedSpeciesID}",
      );

      // Validate positions
      if (formProvider.userLocation == null ||
          formProvider.systemLocation == null) {
        debugPrint(
          "❗ One or both positions are null: "
          "selectedPosition=${formProvider.userLocation}, "
          "currentPosition=${formProvider.systemLocation}",
        );
      }

      // Use actual positions if available, fallback to defaults
      final systemReportLocation =
          formProvider.systemLocation ??
          ReportLocation(latitude: 20.0, longtitude: 20.0);
      final userReportLocation =
          formProvider.userLocation ??
          ReportLocation(latitude: 20.0, longtitude: 20.0);

      // Validate formProvider inputs
      if (formProvider.impactedCrop.isEmpty) {
        throw Exception("Impacted crop is empty");
      }
      if (formProvider.impactedArea == 0) {
        throw Exception("Impacted area is empty");
      }
      final impactedArea = formProvider.impactedArea;
      if (impactedArea == null) {
        throw Exception("Invalid impacted area: ${formProvider.impactedArea}");
      }
      Possesion? pos = _getCorrectPossesion(formProvider.impactedCrop);
      BelongingDamageReport? report;
      if(pos != null){
        report = BelongingDamageReport(
          possesion: pos,
          impactedAreaType: "square-meters",
          impactedArea: impactedArea,
          currentImpactDamages: formProvider.currentDamage,
          estimatedTotalDamages: formProvider.expectedDamage,
          description: formProvider.description,
          suspectedSpeciesID: formProvider.suspectedSpeciesID,
          userSelectedDateTime: DateTime.now(),
          systemDateTime: DateTime.now(),
          systemLocation: systemReportLocation,
          userSelectedLocation: userReportLocation,
        );
      }

      debugPrint("✅ Report created: $report");
      return report;
    } catch (e, stackTrace) {
      debugPrint("❌ Exception in buildReportTesting: $e");
      debugPrint("🔍 Stack trace: $stackTrace");
      rethrow;
    }
  }

  //⌄ This needs to be refactored to use the new Belongings in the new API
  Possesion? _getCorrectPossesion(String name){
    for(Belonging belonging in _mapToListOfBelonging(belongings)){
      if(belonging.name.toLowerCase() == name){
        Possesion correctPossesion = Possesion(
          possesionID: belonging.ID!,
          possesionName: belonging.name,
          category: belonging.category,
        );
        return correctPossesion;
      }
    }
      return null;
  }
}