import 'package:wildrapport/interfaces/reporting/reportable_interface.dart';
import 'package:wildrapport/models/animal_waarneming_models/animal_sighting_model.dart';
import 'package:wildrapport/utils/sighting_api_transformer.dart';

class AnimalSightingReportWrapper implements Reportable {
  final AnimalSightingModel sighting;

  AnimalSightingReportWrapper(this.sighting);

  @override
  Map<String, dynamic> toJson() {
    return SightingApiTransformer.transformForApi(sighting);
  }
}
