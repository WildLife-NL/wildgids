import 'package:wildgids/interfaces/reporting/common_report_fields.dart';
import 'package:wildgids/models/beta_models/possesion_model.dart';

abstract class PossesionReportFields extends CommonReportFields {
  Possesion get possesion;
  double get currentImpactDamages;
  double get estimatedTotalDamages;
  String get impactedAreaType;
  double get impactedArea;
}

