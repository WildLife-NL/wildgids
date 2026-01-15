import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mockito/mockito.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_gender_view_count_model.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_model.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_sighting_model.dart';
import 'package:wildgids/models/enums/animal_gender.dart';
import 'package:wildgids/models/enums/report_type.dart';
import 'package:wildgids/models/animal_waarneming_models/view_count_model.dart';
import '../mock_generator.mocks.dart';

class AnimalCountingHelpers {
  static Future<void> setupEnvironment() async {
    await dotenv.load(fileName: ".env");
  }

  static MockNavigationStateInterface getMockNavigationManager() {
    final mockNavigationManager = MockNavigationStateInterface();
    return mockNavigationManager;
  }

  static MockAnimalSightingReportingInterface getMockAnimalSightingManager() {
    final mock = MockAnimalSightingReportingInterface();

    // Setup default behavior
    when(
      mock.getCurrentanimalSighting(),
    ).thenReturn(createMockAnimalSighting());

    // Setup update methods
    when(mock.updateGender(any)).thenReturn(createMockAnimalSighting());
    when(mock.updateViewCount(any)).thenReturn(createMockAnimalSighting());
    when(
      mock.finalizeAnimal(clearSelected: anyNamed('clearSelected')),
    ).thenReturn(createMockAnimalSighting());
    when(mock.createanimalSighting()).thenReturn(createMockAnimalSighting());

    return mock;
  }

  static MockAppStateProvider getMockAppStateProvider() {
    final mock = MockAppStateProvider();
    when(mock.currentReportType).thenReturn(ReportType.waarneming);
    return mock;
  }

  static AnimalSightingModel createMockAnimalSighting() {
    return AnimalSightingModel(
      animals: [],
      animalSelected: AnimalModel(
        animalId: '1',
        animalName: 'Wolf',
        animalImagePath: 'assets/wolf.png',
        genderViewCounts: [
          AnimalGenderViewCount(
            gender: AnimalGender.mannelijk,
            viewCount: ViewCountModel(
              volwassenAmount: 2,
              onvolwassenAmount: 0,
              pasGeborenAmount: 0,
              unknownAmount: 0,
            ),
          ),
          AnimalGenderViewCount(
            gender: AnimalGender.vrouwelijk,
            viewCount: ViewCountModel(
              volwassenAmount: 1,
              onvolwassenAmount: 0,
              pasGeborenAmount: 0,
              unknownAmount: 0,
            ),
          ),
          AnimalGenderViewCount(
            gender: AnimalGender.onbekend,
            viewCount: ViewCountModel(
              volwassenAmount: 0,
              onvolwassenAmount: 0,
              pasGeborenAmount: 0,
              unknownAmount: 3,
            ),
          ),
        ],
      ),
    );
  }

  static void setupSuccessfulNavigation(
    MockNavigationStateInterface mockNavigationManager,
  ) {
    when(
      mockNavigationManager.pushForward(any, any),
    ).thenAnswer((_) => Future.value(true));
    when(
      mockNavigationManager.pushReplacementForward(any, any),
    ).thenAnswer((_) => Future.value(true));
  }
}

