import 'package:widgets/models/animal_waarneming_models/animal_sighting_model.dart';
import 'package:widgets/utils/sighting_api_transformer.dart';
import 'package:widgets/interfaces/reporting/reportable.dart';

class AnimalSightingReportWrapper implements Reportable {
  final AnimalSightingModel sighting;

  AnimalSightingReportWrapper(this.sighting);

  @override
  Map<String, dynamic> toJson() {
    return SightingApiTransformer.transformForApi(sighting);
  }
}
