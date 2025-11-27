import 'package:wildrapport/models/api_models/vicinity.dart';

abstract class VicinityApiInterface {
  Future<Vicinity> getMyVicinity();
}
