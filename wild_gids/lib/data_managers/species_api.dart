import 'package:widgets/data_managers/api_client.dart';
import 'package:widgets/interfaces/data_apis/species_api_interface.dart';
import 'package:widgets/models/animal_waarneming_models/animal_model.dart';
import 'package:widgets/models/enums/animal_category.dart';
import 'dart:convert';

class SpeciesApi implements SpeciesApiInterface {
  final ApiClient client;

  SpeciesApi(this.client);

  @override
  Future<List<AnimalModel>> getAnimals() async {
    try {
      final response = await client.get('/species', authenticated: true);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => AnimalModel(
          animalId: json['id'],
          animalName: json['commonName'] ?? json['name'] ?? 'Unknown',
          animalImagePath: json['imagePath'],
          genderViewCounts: [],
        )).toList();
      }
      return [];
    } catch (e) {
      print('[SpeciesApi] Error fetching animals: $e');
      return [];
    }
  }

  @override
  Future<List<Species>> getAllSpecies() async {
    try {
      final response = await client.get('/species', authenticated: true);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Species.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('[SpeciesApi] Error fetching species: $e');
      return [];
    }
  }

  @override
  Future<List<AnimalModel>> getAnimalsByCategory(AnimalCategory category) async {
    try {
      final response = await client.get(
        '/species?category=${category.name}',
        authenticated: true,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => AnimalModel(
          animalId: json['id'],
          animalName: json['commonName'] ?? json['name'] ?? 'Unknown',
          animalImagePath: json['imagePath'],
          genderViewCounts: [],
        )).toList();
      }
      return [];
    } catch (e) {
      print('[SpeciesApi] Error fetching animals by category: $e');
      return [];
    }
  }

  @override
  Future<AnimalModel> getAnimalById(String animalId) async {
    try {
      final response = await client.get('/species/$animalId', authenticated: true);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return AnimalModel(
          animalId: data['id'],
          animalName: data['commonName'] ?? data['name'] ?? 'Unknown',
          animalImagePath: data['imagePath'],
          genderViewCounts: [],
        );
      }
      throw Exception('Animal not found');
    } catch (e) {
      print('[SpeciesApi] Error fetching animal by ID: $e');
      rethrow;
    }
  }
}
