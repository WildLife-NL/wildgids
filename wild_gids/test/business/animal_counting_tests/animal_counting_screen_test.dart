import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/interfaces/waarneming_flow/animal_sighting_reporting_interface.dart';
import 'package:wildgids/interfaces/state/navigation_state_interface.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_gender_view_count_model.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_model.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_sighting_model.dart';
import 'package:wildgids/models/enums/animal_gender.dart';
import 'package:wildgids/models/enums/report_type.dart';
import 'package:wildgids/models/animal_waarneming_models/view_count_model.dart';

import 'package:wildgids/providers/app_state_provider.dart';
import 'package:wildgids/screens/waarneming/animal_counting_screen.dart';
import '../mock_generator.mocks.dart';
import 'package:wildgids/models/enums/animal_age.dart';
import 'package:wildgids/models/enums/animal_age_extensions.dart';

void main() {
  late MockNavigationStateInterface mockNavigationManager;
  late MockAnimalSightingReportingInterface mockAnimalSightingManager;
  late MockAppStateProvider mockAppStateProvider;

  setUp(() {
    // Initialize mocks
    mockNavigationManager = MockNavigationStateInterface();
    mockAnimalSightingManager = MockAnimalSightingReportingInterface();
    mockAppStateProvider = MockAppStateProvider();

    // Reset interactions
    reset(mockNavigationManager);
    reset(mockAnimalSightingManager);
    reset(mockAppStateProvider);

    // Setup test data
    when(
      mockAppStateProvider.currentReportType,
    ).thenReturn(ReportType.waarneming);

    // Setup animal sighting data
    final testAnimalSighting = AnimalSightingModel(
      animals: [],
      animalSelected: AnimalModel(
        animalId: '1',
        animalName: 'Wolf',
        animalImagePath: 'assets/wolf.png',
        genderViewCounts: [],
      ),
    );

    when(
      mockAnimalSightingManager.getCurrentanimalSighting(),
    ).thenReturn(testAnimalSighting);

    // Setup navigation
    when(
      mockNavigationManager.pushForward(any, any),
    ).thenAnswer((_) => Future.value(true));
    when(
      mockNavigationManager.pushReplacementForward(any, any),
    ).thenAnswer((_) => Future.value(true));
  });

  Widget createAnimalCountingScreen() {
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
        child: const Scaffold(body: AnimalCountingScreen()),
      ),
    );
  }

  group('AnimalCountingScreen UI Tests', () {
    testWidgets('renders gender selection buttons', (tester) async {
      // Arrange
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;

      // Act
      await tester.pumpWidget(createAnimalCountingScreen());
      await tester.pumpAndSettle();

      // Assert - Check for gender buttons
      expect(find.text('Mannelijk'), findsOneWidget);
      expect(find.text('Vrouwelijk'), findsOneWidget);
      // Use findsWidgets instead of findsOneWidget since there are multiple "Onbekend" texts
      expect(find.text('Onbekend'), findsWidgets);

      // Cleanup
      addTearDown(() => tester.view.resetPhysicalSize());
    });

    testWidgets('gender selection shows age options', (tester) async {
      // Arrange
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpWidget(createAnimalCountingScreen());
      await tester.pumpAndSettle();

      // Act - Select male gender
      await tester.tap(find.text('Mannelijk'));
      await tester.pumpAndSettle();

      // Assert - Check for age options
      expect(find.text('Volwassen'), findsOneWidget);
      expect(find.text(AnimalAge.pasGeboren.label), findsOneWidget);
      expect(find.text('Onvolwassen'), findsOneWidget);

      // Cleanup
      addTearDown(() => tester.view.resetPhysicalSize());
    });

    testWidgets('add to list button is visible', (tester) async {
      // Arrange
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpWidget(createAnimalCountingScreen());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Voeg toe aan de lijst'), findsOneWidget);

      // Cleanup
      addTearDown(() => tester.view.resetPhysicalSize());
    });

    testWidgets('navigation occurs when adding animal to list', (tester) async {
      // Arrange
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;

      // Create a GenderViewCount with a non-zero count to trigger _hasAddedItems
      final genderViewCount = AnimalGenderViewCount(
        gender: AnimalGender.mannelijk,
        viewCount: ViewCountModel(
          volwassenAmount: 1, // Set a non-zero count
          onvolwassenAmount: 0,
          pasGeborenAmount: 0,
          unknownAmount: 0,
        ),
      );

      // Create an animal with the gender view count
      final animalWithCount = AnimalModel(
        animalId: '1',
        animalName: 'Wolf',
        animalImagePath: 'assets/wolf.png',
        genderViewCounts: [genderViewCount],
      );

      // Mock that an animal has been added to the list with counts
      when(mockAnimalSightingManager.getCurrentanimalSighting()).thenReturn(
        AnimalSightingModel(
          animals: [animalWithCount],
          animalSelected: animalWithCount,
        ),
      );

      // Act
      await tester.pumpWidget(createAnimalCountingScreen());
      await tester.pumpAndSettle();

      // The next button should now be visible in the CustomBottomAppBar
      // Look for the "Volgende" text which is the Dutch word for "Next"
      expect(find.text('Volgende'), findsOneWidget);

      // Tap the next button by finding the row containing "Volgende"
      await tester.tap(find.text('Volgende'));
      await tester.pumpAndSettle();

      // Verify navigation was called
      verify(mockNavigationManager.pushReplacementForward(any, any)).called(1);

      // Cleanup
      addTearDown(() => tester.view.resetPhysicalSize());
    });
  });
}

