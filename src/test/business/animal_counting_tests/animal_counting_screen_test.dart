import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/interfaces/state/navigation_state_interface.dart';
import 'package:wildgids/interfaces/waarneming_flow/animal_sighting_reporting_interface.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_model.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_sighting_model.dart';
import 'package:wildgids/models/enums/report_type.dart';
import 'package:wildgids/providers/app_state_provider.dart';
import 'package:wildgids/screens/waarneming/animal_aantal_screen.dart';

import '../mock_generator.mocks.dart';

void main() {
  late MockNavigationStateInterface mockNavigationManager;
  late MockAnimalSightingReportingInterface mockAnimalSightingManager;
  late MockAppStateProvider mockAppStateProvider;

  setUp(() {
    mockNavigationManager = MockNavigationStateInterface();
    mockAnimalSightingManager = MockAnimalSightingReportingInterface();
    mockAppStateProvider = MockAppStateProvider();

    reset(mockNavigationManager);
    reset(mockAnimalSightingManager);
    reset(mockAppStateProvider);

    when(mockAppStateProvider.currentReportType).thenReturn(ReportType.waarneming);

    final testAnimalSighting = AnimalSightingModel(
      animals: [],
      animalSelected: AnimalModel(
        animalId: '1',
        animalName: 'Wolf',
        animalImagePath: 'assets/wolf.png',
        genderViewCounts: [],
      ),
    );

    when(mockAnimalSightingManager.getCurrentanimalSighting()).thenReturn(
      testAnimalSighting,
    );

    when(mockNavigationManager.pushForward(any, any)).thenAnswer((_) async {});
    when(mockNavigationManager.pushReplacementForward(any, any))
        .thenAnswer((_) async {});
  });

  Widget createAnimalAantalScreen() {
    return MaterialApp(
      home: MultiProvider(
        providers: [
          Provider<NavigationStateInterface>.value(
            value: mockNavigationManager,
          ),
          Provider<AnimalSightingReportingInterface>.value(
            value: mockAnimalSightingManager,
          ),
          ChangeNotifierProvider<AppStateProvider>.value(
            value: mockAppStateProvider,
          ),
        ],
        child: const Scaffold(body: AnimalAantalScreen()),
      ),
    );
  }

  group('AnimalAantalScreen UI Tests', () {
    testWidgets('renders quantity question and aantal label', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(createAnimalAantalScreen());
      await tester.pumpAndSettle();

      expect(find.textContaining('Hoeveel van deze dieren'), findsOneWidget);
      expect(find.text('Aantal:'), findsOneWidget);
      expect(find.text('Volgende'), findsOneWidget);

      addTearDown(() => tester.view.resetPhysicalSize());
    });

    testWidgets('shows animal name in card', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(createAnimalAantalScreen());
      await tester.pumpAndSettle();

      expect(find.text('Wolf'), findsWidgets);

      addTearDown(() => tester.view.resetPhysicalSize());
    });
  });
}
