import 'package:widgets/models/animal_waarneming_models/animal_model.dart';
import 'package:widgets/models/enums/animal_category.dart';

// Temporary Species model for API response
class Species {
  final String id;
  final String commonName;
  final String? scientificName;
  
  Species({
    required this.id,
    required this.commonName,
    this.scientificName,
  });
  
  factory Species.fromJson(Map<String, dynamic> json) {
    return Species(
      id: json['id'] ?? '',
      commonName: json['commonName'] ?? json['name'] ?? '',
      scientificName: json['scientificName'],
    );
  }
}

abstract class SpeciesApiInterface {
  /// Fetches all animals from the API
  Future<List<AnimalModel>> getAnimals();
  
  /// Fetches all species from the API
  Future<List<Species>> getAllSpecies();
  
  /// Fetches animals by category from the API
  Future<List<AnimalModel>> getAnimalsByCategory(AnimalCategory category);
  
  /// Fetches a single animal by ID from the API
  Future<AnimalModel> getAnimalById(String animalId);
}
