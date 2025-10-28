import 'package:wildrapport/models/beta_models/interaction_model.dart';
import 'package:wildrapport/models/beta_models/interaction_response_model.dart';

abstract class InteractionApiInterface {
  Future<InteractionResponse> sendInteraction(Interaction interaction);
}
