import 'package:wildgids/models/api_models/interaction_query_result.dart';

abstract class InteractionQueryApiInterface {
  Future<List<InteractionQueryResult>> queryInteractions({
    required double areaLatitude,
    required double areaLongitude,
    required int areaRadiusMeters,
    DateTime? momentAfter,
    DateTime? momentBefore,
  });
}

