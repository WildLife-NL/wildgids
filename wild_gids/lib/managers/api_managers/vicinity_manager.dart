import 'package:wildrapport/data_managers/vicinity_api.dart';
import 'package:wildrapport/models/api_models/vicinity.dart';

/// Manager for vicinity-related operations
class VicinityManager {
  final VicinityApi _api;

  VicinityManager(this._api);

  /// Load vicinity data (animals, detections, interactions)
  Future<Vicinity> loadVicinity() async {
    return await _api.getMyVicinity();
  }
}
