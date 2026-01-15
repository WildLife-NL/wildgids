import 'package:wildgids/models/beta_models/report_location_model.dart';

abstract class CommonReportFields {
  String? get suspectedSpeciesID;
  String? get description;
  ReportLocation? get userSelectedLocation;
  ReportLocation? get systemLocation;
  DateTime? get userSelectedDateTime;
  DateTime get systemDateTime;
}

