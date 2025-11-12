import 'package:wildrapport/models/api_models/detection_pin.dart';

abstract class DetectionsApiInterface {

  Future<List<DetectionPin>> getAllDetections();
}
