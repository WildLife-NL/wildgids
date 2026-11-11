import 'package:wildgids/models/beta_models/sighting_report_model.dart';
import 'package:wildgids/interfaces/reporting/reportable_interface.dart';
import 'package:wildgids/models/beta_models/cached_sighting_report.dart';

typedef ReportFactory = Reportable Function(Map<String, dynamic> json);

final Map<String, ReportFactory> reportFactories = {
  "waarneming":
      (json) =>
          json.containsKey('reportOfSighting')
              ? CachedSightingReport(json)
              : SightingReport.fromJson(json),
};
