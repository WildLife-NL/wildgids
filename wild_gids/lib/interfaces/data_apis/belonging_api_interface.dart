import 'package:wildrapport/models/beta_models/belonging_model.dart';

abstract class BelongingApiInterface {
  Future<List<Belonging>> getAllBelongings();
}
