import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:wildrapport/interfaces/waarneming_flow/animal_interface.dart';
import 'package:wildrapport/interfaces/filters/filter_interface.dart';
import 'package:wildrapport/managers/filtering_system/dropdown_manager.dart';
import 'package:wildrapport/models/ui_models/brown_button_model.dart';
import 'package:wildrapport/models/enums/dropdown_type.dart';
import 'package:wildrapport/models/enums/filter_type.dart';
import 'package:wildrapport/models/enums/location_type.dart';

// Generate mock classes
class MockFilterInterface extends Mock implements FilterInterface {}

class SearchFilterMock extends MockFilterInterface {
  @override
  List<BrownButtonModel> getAvailableFilters(String currentFilter) {
    return [
      BrownButtonModel(
        text: FilterType.search.displayText,
        leftIconPath: FilterType.search.iconPath,
      ),
    ];
  }
}

class DefaultFilterMock extends MockFilterInterface {
  @override
  List<BrownButtonModel> getAvailableFilters(String currentFilter) {
    return [
      BrownButtonModel(
        text: FilterType.alphabetical.displayText,
        leftIconPath: FilterType.alphabetical.iconPath,
      ),
    ];
  }
}

class MockAnimalManagerInterface extends Mock implements AnimalManagerInterface {}
class MockBuildContext extends Mock implements BuildContext {}

void main() {
  late DropdownManager dropdownManager;
  late MockFilterInterface mockFilterManager;
  late MockBuildContext mockContext;

  setUp(() {
    mockFilterManager = DefaultFilterMock();
    mockContext = MockBuildContext();
    dropdownManager = DropdownManager(mockFilterManager);
  });

  group('DropdownManager', () {
    test('should build filter dropdown with correct type', () {
      // Act
      final result = dropdownManager.buildDropdown(
        type: DropdownType.filter,
        selectedValue: 'Filteren',
        isExpanded: false,
        onExpandChanged: (_) {},
        onOptionSelected: (_) {},
        context: mockContext,
      );

      // Assert
      expect(result, isA<Column>());
    });

    test('should build location dropdown with correct type', () {
      // Act
      final result = dropdownManager.buildDropdown(
        type: DropdownType.location,
        selectedValue: LocationType.current.displayText,
        isExpanded: false,
        onExpandChanged: (_) {},
        onOptionSelected: (_) {},
        context: mockContext,
      );

      // Assert
      expect(result, isA<Column>());
    });

    test('should throw UnimplementedError for unknown dropdown type', () {
      // Act & Assert
      expect(
        () => dropdownManager.buildDropdown(
          type: DropdownType.values.last, // Use a value that's not handled
          selectedValue: '',
          isExpanded: false,
          onExpandChanged: (_) {},
          onOptionSelected: (_) {},
          context: mockContext,
        ),
        throwsA(isA<UnimplementedError>()),
      );
    });

    testWidgets('should show filter options when expanded', (WidgetTester tester) async {
      // Build a test widget with the dropdown
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                bool isExpanded = true;
                return dropdownManager.buildDropdown(
                  type: DropdownType.filter,
                  selectedValue: 'Filteren',
                  isExpanded: isExpanded,
                  onExpandChanged: (value) => setState(() => isExpanded = value),
                  onOptionSelected: (_) {},
                  context: context,
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text(FilterType.alphabetical.displayText), findsOneWidget);
    });

    testWidgets('should show location options when expanded', (WidgetTester tester) async {
      // Build a test widget with the dropdown
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                bool isExpanded = true;
                return dropdownManager.buildDropdown(
                  type: DropdownType.location,
                  selectedValue: LocationType.current.displayText,
                  isExpanded: isExpanded,
                  onExpandChanged: (value) => setState(() => isExpanded = value),
                  onOptionSelected: (_) {},
                  context: context,
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - should show all location types except the selected one
      for (var locationType in LocationType.values) {
        if (locationType != LocationType.current) {
          expect(find.text(locationType.displayText), findsOneWidget);
        }
      }
    });

    testWidgets('should show reset filter option when a filter is selected', (WidgetTester tester) async {
      // Build a test widget with the dropdown
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                bool isExpanded = true;
                return dropdownManager.buildDropdown(
                  type: DropdownType.filter,
                  selectedValue: FilterType.alphabetical.displayText,
                  isExpanded: isExpanded,
                  onExpandChanged: (value) => setState(() => isExpanded = value),
                  onOptionSelected: (_) {},
                  context: context,
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Reset filter'), findsOneWidget);
    });

    testWidgets('should show search field for search filter option', (WidgetTester tester) async {
      // Use a different mock that returns search filter
      final searchFilterMock = SearchFilterMock();
      final searchDropdownManager = DropdownManager(searchFilterMock);

      // Build a test widget with the dropdown and provider
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              Provider<AnimalManagerInterface>.value(
                value: MockAnimalManagerInterface(),
              ),
            ],
            child: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  bool isExpanded = true;
                  return searchDropdownManager.buildDropdown(
                    type: DropdownType.filter,
                    selectedValue: 'Filteren',
                    isExpanded: isExpanded,
                    onExpandChanged: (value) => setState(() => isExpanded = value),
                    onOptionSelected: (_) {},
                    context: context,
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Zoek een dier...'), findsOneWidget);
    });
  });
}





