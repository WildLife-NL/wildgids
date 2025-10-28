import 'package:wildrapport/models/beta_models/accident_report_model.dart';
import 'package:wildrapport/models/beta_models/belonging_damage_report_model.dart';
import 'package:wildrapport/models/beta_models/sighting_report_model.dart';
import 'package:wildrapport/interfaces/reporting/reportable_interface.dart';

typedef ReportFactory = Reportable Function(Map<String, dynamic> json);

final Map<String, ReportFactory> reportFactories = {
  "waarneming": (json) => SightingReport.fromJson(json),
  "gewasschade": (json) => BelongingDamageReport.fromJson(json),
  "verkeersongeval": (json) => AccidentReport.fromJson(json),
};
