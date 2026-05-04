import 'package:wildgids/interfaces/reporting/reportable_interface.dart';
import 'package:wildgids/models/beta_models/belonging_damage_report_model.dart';
import 'package:wildgids/utils/damage_report_api_transformer.dart';

class BelongingDamageReportWrapper implements Reportable {
  final BelongingDamageReport report;

  BelongingDamageReportWrapper(this.report);

  @override
  Map<String, dynamic> toJson() {
    return BelongingDamageApiTransformer.transformForApi(report);
  }
}

