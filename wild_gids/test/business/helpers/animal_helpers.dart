import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mockito/mockito.dart';
import 'package:wildgids/interfaces/waarneming_flow/animal_interface.dart';
import 'package:wildgids/interfaces/data_apis/species_api_interface.dart';
import 'package:wildgids/interfaces/filters/filter_interface.dart';
import 'package:wildgids/managers/waarneming_flow/animal_manager.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_model.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_sighting_model.dart';
import 'package:wildgids/models/api_models/species.dart';
import '../mock_generator.mocks.dart';

class AnimalHelpers {
  static Future<void> setupEnvironment() async {
    await dotenv.load(fileName: ".env");
  }

  static MockSpeciesApiInterface getMockSpeciesApi() {
    final mock = MockSpeciesApiInterface();
    return mock;
  }

  static MockFilterInterface getMockFilterManager() {
    final mock = MockFilterInterface();
    when(mock.getAvailableFilters(any)).thenReturn([]);
    when(mock.filterAnimalsAlphabetically(any)).thenReturn([]);
    when(mock.searchAnimals(any, any)).thenReturn([]);
    return mock;
  }

  static AnimalManagerInterface getAnimalManager({
    required SpeciesApiInterface speciesApi,
    required FilterInterface filterManager,
  }) {
    return AnimalManager(speciesApi, filterManager);
  }

  static void setupSpeciesApiResponse(MockSpeciesApiInterface mockApi) {
    final species = [
      Species(id: '1', category: 'Roofdieren', commonName: 'Wolf'),
      Species(id: '2', category: 'Roofdieren', commonName: 'Vos'),
      Species(id: '3', category: 'Evenhoevigen', commonName: 'Ree'),
    ];

    when(mockApi.getAllSpecies()).thenAnswer((_) async => species);
  }

  static AnimalSightingModel createMockAnimalSighting() {
    return AnimalSightingModel(
      animalSelected: AnimalModel(
        animalId: '1',
        animalName: 'Wolf',
        animalImagePath: 'assets/wolf.png',
        genderViewCounts: [],
      ),
    );
  }
}

