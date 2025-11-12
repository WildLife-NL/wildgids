import 'package:wildrapport/interfaces/reporting/common_report_fields.dart';
import 'package:wildrapport/interfaces/reporting/reportable_interface.dart';
import 'package:wildrapport/models/beta_models/report_location_model.dart';
import 'package:wildrapport/models/beta_models/sighted_animal_model.dart';

class AccidentReport implements Reportable, CommonReportFields {
  String? accidentReportID;
  @override
  String? description;
  String damages;
  List<SightedAnimal>? animals;
  @override
  String? suspectedSpeciesID;
  @override
  ReportLocation? userSelectedLocation;
  @override
  ReportLocation? systemLocation;
  @override
  DateTime? userSelectedDateTime;
  @override
  DateTime systemDateTime;
  String intensity;
  String urgency;

  AccidentReport({
    this.accidentReportID,
    this.description,
    required this.damages,
    this.animals,
    this.suspectedSpeciesID,
    this.userSelectedLocation,
    this.systemLocation,
    this.userSelectedDateTime,
    required this.systemDateTime,
    required this.intensity,
    required this.urgency,
  });

  @override
  Map<String, dynamic> toJson() {
    List<dynamic>? listAnimals;
    listAnimals = List<dynamic>.from(animals!.map((x) => x.toJson()));

    return {
      "estimatedDamage": int.tryParse(damages) ?? 0,
      "intensity": intensity,
      "involvedAnimals": listAnimals,
      "urgency": urgency,
    };
  }

  factory AccidentReport.fromJson(Map<String, dynamic> json) => AccidentReport(
    accidentReportID: json["accidentReportID"],
    description: json["description"],
    suspectedSpeciesID: json["suspectedSpeciesID"],
    damages: json["damages"],
    userSelectedLocation: ReportLocation.fromJson(json["userSelectedLocation"]),
    systemLocation: ReportLocation.fromJson(json["systemLocation"]),
    userSelectedDateTime: json["userSelectedDateTime"] != null ? 
        DateTime.parse(json["userSelectedDateTime"]) : null,
    systemDateTime: DateTime.parse(json["systemDateTime"]),
    animals: List<SightedAnimal>.from(
      json["animals"].map((x) => SightedAnimal.fromJson(x)),
    ),
    intensity: json["intensity"],
    urgency: json["urgency"],
  );
}

