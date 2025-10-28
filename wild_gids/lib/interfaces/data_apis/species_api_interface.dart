import 'package:wildrapport/models/api_models/species.dart';

abstract class SpeciesApiInterface {
  Future<List<Species>> getAllSpecies();
  Future<Species> getSpecies(String id);
  Future<Species> getSpeciesByCategory(String category);
}
