import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/interfaces/state/navigation_state_interface.dart';
import 'package:wildgids/interfaces/waarneming_flow/animal_interface.dart';
import 'package:wildgids/interfaces/waarneming_flow/animal_sighting_reporting_interface.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_model.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_sighting_model.dart';
import 'package:wildgids/providers/app_state_provider.dart';
import 'package:wildgids/screens/waarneming/animals_screen.dart';
import '../mock_generator.mocks.dart';

void main() {
  late MockAnimalManagerInterface mockAnimalManager;
  late MockNavigationStateInterface mockNavigationManager;
  late MockAnimalSightingReportingInterface mockAnimalSightingManager;

  final List<AnimalModel> sampleAnimals = [
    AnimalModel(
      animalId: '1',
      animalName: 'Wolf',
      animalImagePath: 'assets/wolf.png',
      genderViewCounts: [],
    ),
    AnimalModel(
      animalId: '2',
      animalName: 'Fox',
      animalImagePath: 'assets/fox.png',
      genderViewCounts: [],
    ),
  ];

  setUp(() {
    mockAnimalManager = MockAnimalManagerInterface();
    mockNavigationManager = MockNavigationStateInterface();
    mockAnimalSightingManager = MockAnimalSightingReportingInterface();

    when(mockAnimalSightingManager.validateActiveAnimalSighting()).thenReturn(true);

    when(mockAnimalManager.getBackendCategories())
        .thenAnswer((_) async => ['Roofdieren']);
    when(mockAnimalManager.getAnimalsByBackendCategory(category: anyNamed('category')))
        .thenAnswer((_) async => sampleAnimals);
    when(mockNavigationManager.pushForward(any, any))
        .thenAnswer((_) async => true);
  });

  Widget createAnimalScreen() {
    return MaterialApp(
      home: MultiProvider(
        providers: [
          Provider<NavigationStateInterface>.value(value: mockNavigationManager),
          Provider<AnimalManagerInterface>.value(value: mockAnimalManager),
          Provider<AnimalSightingReportingInterface>.value(
            value: mockAnimalSightingManager,
          ),
          ChangeNotifierProvider<AppStateProvider>(
            create: (_) => AppStateProvider(),
          ),
        ],
        child: const Scaffold(
          body: SizedBox(
            width: 800,
            height: 1000,
            child: AnimalsScreen(appBarTitle: 'Selecteer Dier'),
          ),
        ),
      ),
    );
  }

  group('AnimalScreen', () {
    testWidgets('renders loaded animal list', (WidgetTester tester) async {
      await tester.pumpWidget(createAnimalScreen());
      await tester.pumpAndSettle();

      expect(find.text('Wolf'), findsOneWidget);
      expect(find.text('Fox'), findsOneWidget);
    });

    testWidgets('shows category dropdown and options', (WidgetTester tester) async {
      await tester.pumpWidget(createAnimalScreen());
      await tester.pumpAndSettle();

      expect(find.text('Categorie'), findsOneWidget);
      expect(find.byType(DropdownButton<String>), findsOneWidget);

      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      expect(find.text('Roofdieren'), findsWidgets);
    });

    testWidgets('selects an animal and navigates forward', (WidgetTester tester) async {
      when(
        mockAnimalSightingManager.processAnimalSelection(any, mockAnimalManager),
      ).thenReturn(AnimalSightingModel(animals: []));

      await tester.pumpWidget(createAnimalScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Wolf').first);
      await tester.pumpAndSettle();

      verify(
        mockAnimalSightingManager.processAnimalSelection(
          argThat(predicate<AnimalModel>((a) => a.animalName == 'Wolf')),
          any,
        ),
      ).called(1);
      verify(mockNavigationManager.pushForward(any, any)).called(1);
    });

    testWidgets('shows empty message for empty animal list', (WidgetTester tester) async {
      when(mockAnimalManager.getAnimalsByBackendCategory(category: anyNamed('category')))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(createAnimalScreen());
      await tester.pumpAndSettle();

      expect(find.text('Geen dieren gevonden'), findsOneWidget);
    });
  });
}

