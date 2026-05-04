import 'package:wildgids/interfaces/reporting/reportable_interface.dart';
import 'package:wildgids/models/beta_models/interaction_response_model.dart';
import 'package:wildgids/models/enums/interaction_type.dart';

abstract class InteractionInterface {
  Future<InteractionResponse?> postInteraction(
    Reportable report,
    InteractionType type,
  );
}

