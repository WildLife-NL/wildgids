import 'package:widgets/models/reports/report_location.dart';

abstract class CommonReportFields {
  String? get description;
  String? get suspectedSpeciesID;
  ReportLocation? get userSelectedLocation;
  ReportLocation? get systemLocation;
  DateTime? get userSelectedDateTime;
}
