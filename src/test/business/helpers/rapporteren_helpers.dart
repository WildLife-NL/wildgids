import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_sighting_model.dart';
import '../mock_generator.mocks.dart';

class RapporterenHelpers {
  static Future<void> setupEnvironment() async {
    // Initialize any environment setup needed for tests
    WidgetsFlutterBinding.ensureInitialized();
  }

  static MockNavigationStateInterface getMockNavigationManager() {
    final mockNavigationManager = MockNavigationStateInterface();
    return mockNavigationManager;
  }

  static MockAnimalSightingReportingInterface getMockAnimalSightingManager() {
    final mockAnimalSightingManager = MockAnimalSightingReportingInterface();
    // Add default stub for createanimalSighting
    when(
      mockAnimalSightingManager.createanimalSighting(),
    ).thenReturn(AnimalSightingModel());
    return mockAnimalSightingManager;
  }

  static MockMapProvider getMockMapProvider() {
    final mockMapProvider = MockMapProvider();

    // Important: Configure all properties and methods used in the Rapporteren screen
    when(mockMapProvider.isInitialized).thenReturn(false);
    when(mockMapProvider.initialize()).thenAnswer((_) => Future.value());

    return mockMapProvider;
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
    when(
      mockNavigationManager.pushAndRemoveUntil(any, any),
    ).thenAnswer((_) => Future.value(true));
  }

  static void setupFailedNavigation(
    MockNavigationStateInterface mockNavigationManager,
  ) {
    when(
      mockNavigationManager.pushForward(any, any),
    ).thenThrow(Exception('Navigation error'));
    when(
      mockNavigationManager.pushReplacementForward(any, any),
    ).thenThrow(Exception('Navigation error'));
    when(
      mockNavigationManager.pushAndRemoveUntil(any, any),
    ).thenThrow(Exception('Navigation error'));
  }
}

