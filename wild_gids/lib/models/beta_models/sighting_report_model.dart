import 'package:widgets/interfaces/reporting/reportable.dart';
import 'package:widgets/interfaces/reporting/common_report_fields.dart';
import 'package:widgets/models/reports/report_location.dart';
import 'package:widgets/models/reports/sighted_animal.dart';

class SightingReport implements Reportable, CommonReportFields {
  final List<SightedAnimal> animals;
  final String? sightingReportID;
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
  final DateTime systemDateTime;

  SightingReport({
    required this.animals,
    this.sightingReportID,
    this.description,
    this.suspectedSpeciesID,
    this.userSelectedLocation,
    this.systemLocation,
    this.userSelectedDateTime,
    required this.systemDateTime,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      "sightingReportID": sightingReportID,
      "description": description,
      "location": systemLocation?.toJson(),
      "moment": userSelectedDateTime?.toIso8601String(),
      "timestamp": systemDateTime.toIso8601String(),
      "place": userSelectedLocation?.toJson(),
      "involvedAnimals": animals.map((a) => a.toJson()).toList(),
      "suspectedSpeciesID": suspectedSpeciesID,
      "typeID": 1,
    };
  }

  factory SightingReport.fromJson(Map<String, dynamic> json) => 
    SightingReport(
      sightingReportID: json["sightingReportID"],
      description: json["description"],
      suspectedSpeciesID: json["suspectedSpeciesID"],
      userSelectedLocation:
          json["place"] != null
              ? ReportLocation.fromJson(json["place"])
              : null,
      systemLocation:
          json["location"] != null
              ? ReportLocation.fromJson(json["location"])
              : null,
      userSelectedDateTime:
          json["moment"] != null
              ? DateTime.parse(json["moment"])
              : null,
      systemDateTime: DateTime.parse(json["timestamp"]),
      animals:
          json["involvedAnimals"] != null
              ? List<SightedAnimal>.from(
                json["involvedAnimals"].map((x) => SightedAnimal.fromJson(x)),
              )
              : [],
    );
}

