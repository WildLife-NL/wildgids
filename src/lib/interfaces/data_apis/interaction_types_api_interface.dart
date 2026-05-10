import 'package:wildgids/models/api_models/interaction_type.dart';

abstract class InteractionTypesApiInterface {
  Future<List<InteractionType>> getAllInteractionTypes();
}

