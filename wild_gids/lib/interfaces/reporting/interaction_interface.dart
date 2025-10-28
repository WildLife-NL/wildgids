import 'package:wildrapport/interfaces/reporting/reportable_interface.dart';
import 'package:wildrapport/models/beta_models/interaction_response_model.dart';
import 'package:wildrapport/models/enums/interaction_type.dart';

abstract class InteractionInterface {
  Future<InteractionResponse?> postInteraction(
    Reportable report,
    InteractionType type,
  );
}
