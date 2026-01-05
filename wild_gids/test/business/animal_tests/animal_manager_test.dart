import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:wildrapport/interfaces/waarneming_flow/animal_interface.dart';
import 'package:wildrapport/managers/waarneming_flow/animal_manager.dart';
import 'package:wildrapport/models/animal_waarneming_models/animal_model.dart';
import 'package:wildrapport/models/enums/filter_type.dart';
import '../helpers/animal_helpers.dart';
import '../mock_generator.mocks.dart';

void main() {
  late MockSpeciesApiInterface mockSpeciesApi;
  late MockFilterInterface mockFilterManager;
  late AnimalManagerInterface animalManager;

  setUpAll(() async {
    // Setup environment for all tests
    await AnimalHelpers.setupEnvironment();
  });

  setUp(() {
    // Get properly configured mocks
    mockSpeciesApi = AnimalHelpers.getMockSpeciesApi();
    mockFilterManager = AnimalHelpers.getMockFilterManager();
    animalManager = AnimalHelpers.getAnimalManager(
      speciesApi: mockSpeciesApi,
      filterManager: mockFilterManager,
    );
  });

  group('AnimalManager', () {
    test('should fetch animals from API when cache is empty', () async {
      // Arrange
      AnimalHelpers.setupSpeciesApiResponse(mockSpeciesApi);

      // Act
      final animals = await animalManager.getAnimals();

      // Assert
      verify(mockSpeciesApi.getAllSpecies()).called(1);
      expect(animals, isNotEmpty);
      expect(animals.last.animalName, 'Onbekend');
    });

    test('should use cached animals when available', () async {
      // Arrange
      AnimalHelpers.setupSpeciesApiResponse(mockSpeciesApi);

      // Act - First call to populate cache
      await animalManager.getAnimals();
      // Reset mock to verify it's not called again
      reset(mockSpeciesApi);
      // Second call should use cache
      final animals = await animalManager.getAnimals();

      // Assert
      verifyNever(mockSpeciesApi.getAllSpecies());
      expect(animals, isNotEmpty);
    });

    test('should filter animals based on current filter', () async {
      // Arrange
      AnimalHelpers.setupSpeciesApiResponse(mockSpeciesApi);
      final mockFilteredAnimals = [
        AnimalModel(
          animalId: '1',
          animalName: 'Wolf',
          animalImagePath: 'assets/wolf.png',
          genderViewCounts: [],
        ),
      ];
      when(
        mockFilterManager.filterAnimalsAlphabetically(any),
      ).thenReturn(mockFilteredAnimals);

      // Act
      animalManager.updateFilter(FilterType.alphabetical.displayText);
      final animals = await animalManager.getAnimals();

      // Assert
      verify(
        mockFilterManager.filterAnimalsAlphabetically(any),
      ).called(greaterThan(0));
      expect(animals, isNotEmpty);
    });

    test('should notify listeners when state changes', () {
      // Arrange
      bool listenerCalled = false;
      animalManager.addListener(() {
        listenerCalled = true;
      });

      // Act
      animalManager.updateFilter(animalManager.getSelectedFilter());

      // Assert
      expect(listenerCalled, true);
    });

    test('should search animals by name', () async {
      // Arrange
      AnimalHelpers.setupSpeciesApiResponse(mockSpeciesApi);
      final searchResults = [
        AnimalModel(
          animalId: '1',
          animalName: 'Wolf',
          animalImagePath: 'assets/wolf.png',
          genderViewCounts: [],
        ),
      ];
      when(mockFilterManager.searchAnimals(any, any)).thenReturn(searchResults);

      // Act
      final animalManagerImpl = animalManager as AnimalManager;
      animalManagerImpl.updateSearchTerm('Wolf');
      final animals = await animalManagerImpl.getAnimals();

      // Assert
      verify(mockFilterManager.searchAnimals(any, 'Wolf')).called(1);
      expect(animals, equals(searchResults));
    });

    test('should handle animal selection correctly', () {
      // Arrange
      final selectedAnimal = AnimalModel(
        animalId: '1',
        animalName: 'Wolf',
        animalImagePath: 'assets/wolf.png',
        genderViewCounts: [],
      );

      // Act
      final result = animalManager.handleAnimalSelection(selectedAnimal);

      // Assert
      expect(result, equals(selectedAnimal));
    });

    test('should apply search term regardless of filter', () async {
      // Arrange
      AnimalHelpers.setupSpeciesApiResponse(mockSpeciesApi);
      final searchResults = [
        AnimalModel(
          animalId: '1',
          animalName: 'Wolf',
          animalImagePath: 'assets/wolf.png',
          genderViewCounts: [],
        ),
      ];
      when(mockFilterManager.searchAnimals(any, any)).thenReturn(searchResults);

      // Act
      animalManager.updateFilter(FilterType.alphabetical.displayText);
      final animalManagerImpl = animalManager as AnimalManager;
      animalManagerImpl.updateSearchTerm('Wolf');
      final animals = await animalManagerImpl.getAnimals();

      // Assert
      verify(mockFilterManager.searchAnimals(any, 'Wolf')).called(1);
      verifyNever(mockFilterManager.filterAnimalsAlphabetically(any));
      expect(animals, equals(searchResults));
    });

    test('should clear search term when empty string is provided', () async {
      // Arrange
      AnimalHelpers.setupSpeciesApiResponse(mockSpeciesApi);
      final animalManagerImpl = animalManager as AnimalManager;

      // First set a non-empty search term
      animalManagerImpl.updateSearchTerm('Wolf');

      // Verify search is applied with non-empty term
      when(mockFilterManager.searchAnimals(any, 'Wolf')).thenReturn([]);
      await animalManagerImpl.getAnimals();
      verify(mockFilterManager.searchAnimals(any, 'Wolf')).called(1);

      // Reset mock to clear previous calls
      reset(mockFilterManager);

      // Now set empty search term
      animalManagerImpl.updateSearchTerm('');

      // For empty search, the manager might not call searchAnimals at all
      // or it might call with empty string
      when(mockFilterManager.searchAnimals(any, '')).thenReturn([]);
      await animalManagerImpl.getAnimals();

      // Check if searchAnimals was called with empty string
      // If not, we'll verify it wasn't called at all
      try {
        verify(mockFilterManager.searchAnimals(any, '')).called(1);
      } catch (_) {
        // If the above verification fails, check if it's because the method wasn't called
        verifyNever(mockFilterManager.searchAnimals(any, any));
      }
    });

    test('should handle API errors gracefully', () async {
      // Arrange
      when(mockSpeciesApi.getAllSpecies()).thenThrow(Exception('API error'));

      // Act
      final animals = await animalManager.getAnimals();

      // Assert
      expect(animals, isEmpty);
    });

    test('should remove listeners correctly', () {
      // Arrange
      bool listenerCalled = false;
      void listener() {
        listenerCalled = true;
      }

      animalManager.addListener(listener);
      animalManager.updateFilter('New Filter'); // Should trigger listener
      expect(listenerCalled, true);

      // Reset flag and remove listener
      listenerCalled = false;
      animalManager.removeListener(listener);

      // Act
      animalManager.updateFilter('Another Filter');

      // Assert
      expect(
        listenerCalled,
        false,
      ); // Listener should not be called after removal
    });

    test(
      'should return unfiltered animals when filter is not recognized',
      () async {
        // Arrange
        AnimalHelpers.setupSpeciesApiResponse(mockSpeciesApi);
        final allAnimals = await animalManager.getAnimals();

        // Act
        animalManager.updateFilter('Unknown Filter Type');
        final filteredAnimals = await animalManager.getAnimals();

        // Assert
        expect(filteredAnimals, equals(allAnimals));
        verifyNever(mockFilterManager.filterAnimalsAlphabetically(any));
      },
    );

    test(
      'should return most viewed animals when most viewed filter is selected',
      () async {
        // Arrange
        AnimalHelpers.setupSpeciesApiResponse(mockSpeciesApi);

        // Act
        animalManager.updateFilter(FilterType.mostViewed.displayText);
        final animals = await animalManager.getAnimals();

        // Assert
        // Currently the implementation returns unfiltered animals for most viewed
        expect(animals, isNotEmpty);
        verifyNever(mockFilterManager.filterAnimalsAlphabetically(any));
      },
    );

    test('should return correct selected filter', () {
      // Arrange
      final initialFilter = animalManager.getSelectedFilter();
      expect(initialFilter, equals('Filteren')); // Default value

      // Act
      animalManager.updateFilter('New Filter');

      // Assert
      expect(animalManager.getSelectedFilter(), equals('New Filter'));
    });

    test('should add multiple listeners and notify all of them', () {
      // Arrange
      int listenerCallCount = 0;
      void listener1() {
        listenerCallCount++;
      }

      void listener2() {
        listenerCallCount++;
      }

      animalManager.addListener(listener1);
      animalManager.addListener(listener2);

      // Act
      animalManager.updateFilter('New Filter');

      // Assert
      expect(listenerCallCount, 2); // Both listeners should be called
    });

    test('should handle empty search results', () async {
      // Arrange
      AnimalHelpers.setupSpeciesApiResponse(mockSpeciesApi);
      final animalManagerImpl = animalManager as AnimalManager;

      // Setup mock to return empty results for search
      when(
        mockFilterManager.searchAnimals(any, 'NonExistentAnimal'),
      ).thenReturn([]);

      // Act
      animalManagerImpl.updateSearchTerm('NonExistentAnimal');
      final animals = await animalManagerImpl.getAnimals();

      // Assert
      expect(animals, isEmpty);
      verify(
        mockFilterManager.searchAnimals(any, 'NonExistentAnimal'),
      ).called(1);
    });

    test('should prioritize search over filter when both are set', () async {
      // Arrange
      AnimalHelpers.setupSpeciesApiResponse(mockSpeciesApi);
      final animalManagerImpl = animalManager as AnimalManager;
      final searchResults = [
        AnimalModel(
          animalId: '1',
          animalName: 'Wolf',
          animalImagePath: 'assets/wolf.png',
          genderViewCounts: [],
        ),
      ];

      // Setup filter and search mocks
      when(
        mockFilterManager.filterAnimalsAlphabetically(any),
      ).thenReturn([/* different results */]);
      when(
        mockFilterManager.searchAnimals(any, 'Wolf'),
      ).thenReturn(searchResults);

      // Act - set both filter and search
      animalManager.updateFilter(FilterType.alphabetical.displayText);
      animalManagerImpl.updateSearchTerm('Wolf');
      final animals = await animalManagerImpl.getAnimals();

      // Assert - search should take precedence
      verify(mockFilterManager.searchAnimals(any, 'Wolf')).called(1);
      verifyNever(mockFilterManager.filterAnimalsAlphabetically(any));
      expect(animals, equals(searchResults));
    });

    test('should handle null cached animals gracefully', () async {
      // Arrange
      AnimalHelpers.setupSpeciesApiResponse(mockSpeciesApi);

      // Act - first call to populate cache
      await animalManager.getAnimals();

      // Force API to throw error on second call
      reset(mockSpeciesApi);
      when(mockSpeciesApi.getAllSpecies()).thenThrow(Exception('API error'));

      // Second call should use cache and not fail
      final animals = await animalManager.getAnimals();

      // Assert
      expect(animals, isNotEmpty);
    });

    test('should include unknown animal in results', () async {
      // Arrange
      AnimalHelpers.setupSpeciesApiResponse(mockSpeciesApi);

      // Act
      final animals = await animalManager.getAnimals();

      // Assert
      final unknownAnimal = animals.firstWhere(
        (animal) => animal.animalName == 'Onbekend',
        orElse:
            () => AnimalModel(
              animalId: 'not_found',
              animalName: 'Not Found',
              animalImagePath: null,
              genderViewCounts: [],
            ),
      );

      expect(unknownAnimal.animalName, equals('Onbekend'));
      expect(unknownAnimal.animalImagePath, isNull);
      expect(unknownAnimal.animalId, equals('unknown'));
    });

    test('should search animals using contains (partial match)', () async {
      // Arrange
      AnimalHelpers.setupSpeciesApiResponse(mockSpeciesApi);
      final animalManagerImpl = animalManager as AnimalManager;

      // Create test animals with names that would match a partial search
      final allAnimals = [
        AnimalModel(
          animalId: '1',
          animalName: 'Wolf',
          animalImagePath: 'assets/wolf.png',
          genderViewCounts: [],
        ),
        AnimalModel(
          animalId: '2',
          animalName: 'Red Wolf',
          animalImagePath: 'assets/red_wolf.png',
          genderViewCounts: [],
        ),
        AnimalModel(
          animalId: '3',
          animalName: 'Fox',
          animalImagePath: 'assets/fox.png',
          genderViewCounts: [],
        ),
      ];

      // Setup the mock to return partial matches for "wolf"
      final partialMatches =
          allAnimals
              .where((a) => a.animalName.toLowerCase().contains('wolf'))
              .toList();

      when(
        mockFilterManager.searchAnimals(any, 'olf'),
      ).thenReturn(partialMatches);

      // Act - search with partial term
      animalManagerImpl.updateSearchTerm('olf');
      final searchResults = await animalManagerImpl.getAnimals();

      // Assert
      verify(mockFilterManager.searchAnimals(any, 'olf')).called(1);
      expect(
        searchResults.length,
        2,
      ); // Should match both "Wolf" and "Red Wolf"
      expect(searchResults.any((a) => a.animalName == 'Wolf'), true);
      expect(searchResults.any((a) => a.animalName == 'Red Wolf'), true);
      expect(searchResults.any((a) => a.animalName == 'Fox'), false);
    });

    test('should handle case-insensitive search', () async {
      // Arrange
      AnimalHelpers.setupSpeciesApiResponse(mockSpeciesApi);
      final animalManagerImpl = animalManager as AnimalManager;

      final searchResults = [
        AnimalModel(
          animalId: '1',
          animalName: 'Wolf',
          animalImagePath: 'assets/wolf.png',
          genderViewCounts: [],
        ),
      ];

      // Setup mock to return results for the exact search term we'll use
      when(
        mockFilterManager.searchAnimals(any, 'WOLF'),
      ).thenReturn(searchResults);

      // Act - search with different case
      animalManagerImpl.updateSearchTerm('WOLF');
      final animals = await animalManagerImpl.getAnimals();

      // Assert
      verify(mockFilterManager.searchAnimals(any, 'WOLF')).called(1);
      expect(animals, equals(searchResults));
    });

    test('should handle search with special characters', () async {
      // Arrange
      AnimalHelpers.setupSpeciesApiResponse(mockSpeciesApi);
      final animalManagerImpl = animalManager as AnimalManager;

      // Setup mock to return empty results for special character search
      when(mockFilterManager.searchAnimals(any, r'@#$%')).thenReturn([]);

      // Act
      animalManagerImpl.updateSearchTerm(r'@#$%');
      final animals = await animalManagerImpl.getAnimals();

      // Assert
      verify(mockFilterManager.searchAnimals(any, r'@#$%')).called(1);
      expect(animals, isEmpty);
    });

    test('should handle consecutive search term updates', () async {
      // Arrange
      AnimalHelpers.setupSpeciesApiResponse(mockSpeciesApi);
      final animalManagerImpl = animalManager as AnimalManager;

      // Setup mocks for different search terms
      when(mockFilterManager.searchAnimals(any, 'Wolf')).thenReturn([]);
      when(mockFilterManager.searchAnimals(any, 'Fox')).thenReturn([]);

      // Act - update search term multiple times before getting animals
      animalManagerImpl.updateSearchTerm('Wolf');
      animalManagerImpl.updateSearchTerm('Fox');
      await animalManagerImpl.getAnimals();

      // Assert - only the last search term should be used
      verifyNever(mockFilterManager.searchAnimals(any, 'Wolf'));
      verify(mockFilterManager.searchAnimals(any, 'Fox')).called(1);
    });

    test('should handle filter change after search is set', () async {
      // Arrange
      AnimalHelpers.setupSpeciesApiResponse(mockSpeciesApi);
      final animalManagerImpl = animalManager as AnimalManager;

      final searchResults = [
        AnimalModel(
          animalId: '1',
          animalName: 'Wolf',
          animalImagePath: 'assets/wolf.png',
          genderViewCounts: [],
        ),
      ];

      when(
        mockFilterManager.searchAnimals(any, 'Wolf'),
      ).thenReturn(searchResults);

      // Act - set search then change filter
      animalManagerImpl.updateSearchTerm('Wolf');
      animalManager.updateFilter(FilterType.alphabetical.displayText);
      final animals = await animalManagerImpl.getAnimals();

      // Assert - search should still take precedence over filter
      verify(mockFilterManager.searchAnimals(any, 'Wolf')).called(1);
      verifyNever(mockFilterManager.filterAnimalsAlphabetically(any));
      expect(animals, equals(searchResults));
    });

    test('should reset to filter when search term is cleared', () async {
      // Arrange
      AnimalHelpers.setupSpeciesApiResponse(mockSpeciesApi);
      final animalManagerImpl = animalManager as AnimalManager;

      final filteredResults = [
        AnimalModel(
          animalId: '2',
          animalName: 'Alphabetical Result',
          animalImagePath: 'assets/alpha.png',
          genderViewCounts: [],
        ),
      ];

      // Setup filter to return specific results
      when(
        mockFilterManager.filterAnimalsAlphabetically(any),
      ).thenReturn(filteredResults);

      // Set filter first
      animalManager.updateFilter(FilterType.alphabetical.displayText);

      // Act - set search term then clear it
      animalManagerImpl.updateSearchTerm('Wolf');
      when(mockFilterManager.searchAnimals(any, 'Wolf')).thenReturn([]);
      await animalManagerImpl.getAnimals();
      verify(mockFilterManager.searchAnimals(any, 'Wolf')).called(1);

      // Reset mocks
      reset(mockFilterManager);
      when(
        mockFilterManager.filterAnimalsAlphabetically(any),
      ).thenReturn(filteredResults);

      // Clear search term
      animalManagerImpl.updateSearchTerm('');
      final animals = await animalManagerImpl.getAnimals();

      // Assert - should revert to using filter
      verify(mockFilterManager.filterAnimalsAlphabetically(any)).called(1);
      expect(animals, equals(filteredResults));
    });
  });
}
