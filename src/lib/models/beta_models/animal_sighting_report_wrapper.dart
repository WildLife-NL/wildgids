import 'package:wildgids/interfaces/reporting/reportable_interface.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_sighting_model.dart';
import 'package:wildgids/utils/sighting_api_transformer.dart';

class AnimalSightingReportWrapper implements Reportable {
  final AnimalSightingModel sighting;

  AnimalSightingReportWrapper(this.sighting);

  @override
  Map<String, dynamic> toJson() {
    return SightingApiTransformer.transformForApi(sighting);
  }
}

