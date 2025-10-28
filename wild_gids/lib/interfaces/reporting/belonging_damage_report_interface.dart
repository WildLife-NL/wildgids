import 'package:wildrapport/models/beta_models/interaction_response_model.dart';
import 'package:wildrapport/models/beta_models/belonging_damage_report_model.dart';
import 'package:wildrapport/models/beta_models/report_location_model.dart';

abstract class BelongingDamageReportInterface {
  List<dynamic> buildPossesionWidgetList();
  Future<InteractionResponse?> postInteraction();
  void updateImpactedCrop(String value);
  void updateCurrentDamage(double value);
  void updateExpectedDamage(double value);
  void updateImpactedAreaType(String value);
  void updateImpactedArea(double value);
  void updateDescription(String value);
  void updateSuspectedAnimal(String value);
  void updateSystemLocation(ReportLocation value);
  void updateUserLocation(ReportLocation value);
  BelongingDamageReport? buildBelongingReport();
}
