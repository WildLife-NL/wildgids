import 'package:wildgids/models/reports/base_report.dart';

class WaarnemingReport extends BaseReport {
  WaarnemingReport() : super('Waarnemingen');

  // Add specific getters/setters for Waarneming properties
  String? get selectedAnimal => getProperty('selectedAnimal');
  set selectedAnimal(String? value) => updateProperty('selectedAnimal', value);

  DateTime? get observationDate => getProperty('observationDate');
  set observationDate(DateTime? value) =>
      updateProperty('observationDate', value);
}

