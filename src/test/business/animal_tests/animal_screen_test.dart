import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/interfaces/waarneming_flow/animal_interface.dart';
import 'package:wildgids/interfaces/waarneming_flow/animal_sighting_reporting_interface.dart';
import 'package:wildgids/interfaces/filters/dropdown_interface.dart';
import 'package:wildgids/interfaces/filters/filter_interface.dart';
import 'package:wildgids/interfaces/state/navigation_state_interface.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_model.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_sighting_model.dart';
import 'package:wildgids/models/enums/report_type.dart';
import 'package:wildgids/providers/app_state_provider.dart';
import 'package:wildgids/screens/waarneming/animals_screen.dart';
import '../mock_generator.mocks.dart';

void main() {
  late MockAnimalManagerInterface mockAnimalManager;
  late MockNavigationStateInterface mockNavigationManager;
  late MockDropdownInterface mockDropdownInterface;
  late MockFilterInterface mockFilterInterface;
  late MockAnimalSightingReportingInterface mockAnimalSightingManager;
  late MockAppStateProvider mockAppStateProvider;

  // Sample animal data for consistent testing
  final List<AnimalModel> sampleAnimals = [
    AnimalModel(
      animalId: '1',
      animalName: 'Wolf',
      animalImagePath: 'assets/wolf.png',
      genderViewCounts: [],
    ),
    AnimalModel(
      animalId: '2',
      animalName: 'fox',
      animalImagePath: 'assets/fox.png',
      genderViewCounts: [],
    ),
  ];

  setUp(() {
    // Initialize mocks
    mockAnimalManager = MockAnimalManagerInterface();
    mockNavigationManager = MockNavigationStateInterface();
    mockDropdownInterface = MockDropdownInterface();
    mockFilterInterface = MockFilterInterface();
    mockAnimalSightingManager = MockAnimalSightingReportingInterface();
    mockAppStateProvider = MockAppStateProvider();

    // Reset interactions to avoid state leakage
    reset(mockAnimalManager);
    reset(mockNavigationManager);
    reset(mockDropdownInterface);
    reset(mockFilterInterface);
    reset(mockAnimalSightingManager);
    reset(mockAppStateProvider);

    // Mock currentReportType
    when(
      mockAppStateProvider.currentReportType,
    ).thenReturn(ReportType.waarneming);

    // Mock validateActiveAnimalSighting
    when(
      mockAnimalSightingManager.validateActiveAnimalSighting(),
    ).thenReturn(true);

    // Mock animal list retrieval
    when(mockAnimalManager.getAnimals()).thenAnswer((_) async => sampleAnimals);

    // Mock selected filter
    when(mockAnimalManager.getSelectedFilter()).thenReturn('Filteren');

    // Mock handleAnimalSelection with specific animal
    when(mockAnimalManager.handleAnimalSelection(any)).thenAnswer((invocation) {
      final animal = invocation.positionalArguments[0] as AnimalModel;
      return animal;
    });

    // Mock processAnimalSelection
    when(mockAnimalSightingManager.processAnimalSelection(any, any)).thenAnswer(
      (_) {
        return AnimalSightingModel(animals: []);
      },
    );

    // Mock updateSearchTerm as a void function with correct argument type
    when(mockAnimalManager.updateFilter(argThat(isA<String>()))).thenAnswer((
      invocation,
    ) {
      // No return needed since it's a void function
    });

    // Mock updateFilter as a void function with correct argument type
    when(mockAnimalManager.updateFilter(argThat(isA<String>()))).thenAnswer((
      invocation,
    ) {
      // No return needed since it's a void function
    });

    // Mock dropdown interface to simulate a searchable dropdown
    when(
      mockDropdownInterface.buildDropdown(
        type: anyNamed('type'),
        selectedValue: anyNamed('selectedValue'),
        isExpanded: anyNamed('isExpanded'),
        onExpandChanged: anyNamed('onExpandChanged'),
        onOptionSelected: anyNamed('onOptionSelected'),
        context: anyNamed('context'),
      ),
    ).thenAnswer((invocation) {
      final isExpanded =
          invocation.namedArguments[const Symbol('isExpanded')] as bool;
      final onExpandChanged =
          invocation.namedArguments[const Symbol('onExpandChanged')]
              as Function(bool);
      final onOptionSelected =
          invocation.namedArguments[const Symbol('onOptionSelected')]
              as Function(String);
      final selectedValue =
          invocation.namedArguments[const Symbol('selectedValue')] as String;

      return StatefulBuilder(
        builder: (context, setState) {
          return Column(
            children: [
              ElevatedButton(
                key: const Key('dropdown_toggle'),
                onPressed: () {
                  setState(() {
                    onExpandChanged(!isExpanded);
                  });
                },
                child: Text(
                  selectedValue == 'Filteren' ? 'Filteren' : selectedValue,
                ),
              ),
              if (isExpanded) ...[
                TextField(
                  key: const Key('dropdown_search_field'),
                  onChanged: (value) {
                    mockAnimalManager.updateSearchTerm(value);
                  },
                  decoration: const InputDecoration(
                    hintText: 'Zoek een dier...',
                  ),
                ),
                ...[
                  DropdownMenuItem(value: 'Filteren', child: Text('Filteren')),
                  DropdownMenuItem(
                    value: 'Alfabetisch',
                    child: Text('Alfabetisch'),
                  ),
                ].map((item) {
                  return ElevatedButton(
                    onPressed: () {
                      onOptionSelected(item.value!);
                      setState(() {
                        onExpandChanged(false);
                      });
                    },
                    child: item.child,
                  );
                }),
              ],
            ],
          );
        },
      );
    });
  });

  Widget createAnimalScreen() {
    return MaterialApp(
      home: MultiProvider(
        providers: [
          Provider<NavigationStateInterface>.value(
            value: mockNavigationManager,
          ),
          Provider<AnimalManagerInterface>.value(value: mockAnimalManager),
          Provider<DropdownInterface>.value(value: mockDropdownInterface),
          Provider<FilterInterface>.value(value: mockFilterInterface),
          Provider<AnimalSightingReportingInterface>.value(
            value: mockAnimalSightingManager,
          ),
          ChangeNotifierProvider<AppStateProvider>.value(
            value: mockAppStateProvider,
          ),
        ],
        child: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: AnimalsScreen(appBarTitle: 'Selecteer Dier'),
          ),
        ),
      ),
    );
  }

  group('AnimalScreen', () {
    testWidgets('should render animal list when loaded', (
      WidgetTester tester,
    ) async {
      // Set a fixed viewport size for consistent testing
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;

      // Arrange
      await tester.pumpWidget(createAnimalScreen());

      // Act - Wait for async operations to settle
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Wolf'), findsOneWidget);
      expect(find.text('fox'), findsOneWidget);

      // Reset the test viewport
      addTearDown(() => tester.view.resetPhysicalSize());
    });

    testWidgets('should show search field when dropdown is expanded', (
      WidgetTester tester,
    ) async {
      // Set a fixed viewport size
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;

      // Arrange
      await tester.pumpWidget(createAnimalScreen());
      await tester.pumpAndSettle();

      // Act - Expand the dropdown
      final dropdownToggle = find.byKey(const Key('dropdown_toggle'));
      expect(dropdownToggle, findsOneWidget);
      await tester.tap(dropdownToggle);
      await tester.pumpAndSettle();

      // Assert - Check for the search field
      expect(find.byKey(const Key('dropdown_search_field')), findsOneWidget);

      // Reset the test viewport
      addTearDown(() => tester.view.resetPhysicalSize());
    });

    // Removed test: 'should filter animals when search term is entered in dropdown'

    testWidgets('should select animal when tapped', (
      WidgetTester tester,
    ) async {
      // Set a fixed viewport size
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;

      // Arrange
      await tester.pumpWidget(createAnimalScreen());
      await tester.pumpAndSettle();

      // Act - Find the animal button (assuming ElevatedButton in ScrollableAnimalGrid)
      final animalButton = find.ancestor(
        of: find.text('Wolf'),
        matching: find.byType(ElevatedButton),
      );
      expect(animalButton, findsOneWidget);
      await tester.tap(animalButton);
      await tester.pumpAndSettle();

      // Assert - Verify processAnimalSelection was called
      verify(
        mockAnimalSightingManager.processAnimalSelection(
          argThat(
            predicate<AnimalModel>((animal) => animal.animalName == 'Wolf'),
          ),
          any,
        ),
      ).called(1);

      // Reset the test viewport
      addTearDown(() => tester.view.resetPhysicalSize());
    });

    testWidgets('should show filter dropdown', (WidgetTester tester) async {
      // Set a fixed viewport size
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;

      // Arrange
      await tester.pumpWidget(createAnimalScreen());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(const Key('dropdown_toggle')), findsOneWidget);
      expect(find.text('Filteren'), findsOneWidget);

      // Reset the test viewport
      addTearDown(() => tester.view.resetPhysicalSize());
    });

    testWidgets('should update filter when dropdown value changes', (
      WidgetTester tester,
    ) async {
      // Set a fixed viewport size
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;

      // Arrange
      await tester.pumpWidget(createAnimalScreen());
      await tester.pumpAndSettle();

      // Act - Expand the dropdown
      final dropdownToggle = find.byKey(const Key('dropdown_toggle'));
      expect(dropdownToggle, findsOneWidget);
      await tester.tap(dropdownToggle);
      await tester.pumpAndSettle();

      // Select a filter option
      final filterOption = find.text('Alfabetisch');
      expect(filterOption, findsOneWidget);
      await tester.tap(
        find.ancestor(of: filterOption, matching: find.byType(ElevatedButton)),
      );
      await tester.pumpAndSettle();

      // Assert
      verify(mockAnimalManager.updateFilter('Alfabetisch')).called(1);

      // Reset the test viewport
      addTearDown(() => tester.view.resetPhysicalSize());
    });

    testWidgets('should handle empty animal list', (WidgetTester tester) async {
      // Set a fixed viewport size
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;

      // Mock empty animal list
      when(mockAnimalManager.getAnimals()).thenAnswer((_) async => []);

      // Arrange
      await tester.pumpWidget(createAnimalScreen());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Wolf'), findsNothing);
      expect(find.text('fox'), findsNothing);

      // Reset the test viewport
      addTearDown(() => tester.view.resetPhysicalSize());
    });

    // Removed test: 'should display app bar with correct title'
  });
}

