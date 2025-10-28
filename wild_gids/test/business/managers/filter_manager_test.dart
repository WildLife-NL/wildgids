import 'package:flutter_test/flutter_test.dart';
import 'package:wildrapport/interfaces/filters/filter_interface.dart';
import 'package:wildrapport/managers/filtering_system/filter_manager.dart';
import 'package:wildrapport/models/animal_waarneming_models/animal_model.dart';
import 'package:wildrapport/models/enums/filter_type.dart';

void main() {
  late FilterInterface filterManager;

  setUp(() {
    filterManager = FilterManager();
  });

  group('FilterManager', () {
    test('should return all filter options when no filter is selected', () {
      // Act
      final filters = filterManager.getAvailableFilters('Filteren');
      
      // Assert
      expect(filters.length, 3);
      expect(filters[0].text, FilterType.alphabetical.displayText);
      expect(filters[1].text, FilterType.mostViewed.displayText);
      expect(filters[2].text, FilterType.search.displayText);
    });

    test('should return all filter options when empty filter is provided', () {
      // Act
      final filters = filterManager.getAvailableFilters('');
      
      // Assert
      expect(filters.length, 3);
    });

    test('should return all filter options except the selected one', () {
      // Act
      final filters = filterManager.getAvailableFilters(FilterType.alphabetical.displayText);
      
      // Assert
      expect(filters.length, 2);
      expect(filters.any((f) => f.text == FilterType.alphabetical.displayText), false);
      expect(filters.any((f) => f.text == FilterType.mostViewed.displayText), true);
      expect(filters.any((f) => f.text == FilterType.search.displayText), true);
    });

    test('should filter animals alphabetically', () {
      // Arrange
      final animals = [
        AnimalModel(animalId: '1', animalName: 'Wolf', animalImagePath: 'path1', genderViewCounts: []),
        AnimalModel(animalId: '2', animalName: 'Aardvark', animalImagePath: 'path2', genderViewCounts: []),
        AnimalModel(animalId: '3', animalName: 'Zebra', animalImagePath: 'path3', genderViewCounts: []),
        AnimalModel(animalId: '4', animalName: 'Onbekend', animalImagePath: 'path4', genderViewCounts: []),
      ];
      
      // Act
      final filteredAnimals = filterManager.filterAnimalsAlphabetically(animals);
      
      // Assert
      expect(filteredAnimals.length, 4);
      expect(filteredAnimals[0].animalName, 'Aardvark');
      expect(filteredAnimals[1].animalName, 'Wolf');
      expect(filteredAnimals[2].animalName, 'Zebra');
      expect(filteredAnimals[3].animalName, 'Onbekend'); // Should be last
    });

    test('should return animal categories with icons', () {
      // Act
      final categories = (filterManager as FilterManager).getAnimalCategories();
      
      // Assert
      expect(categories.length, 3);
      expect(categories[0]['text'], 'Evenhoevigen');
      expect(categories[1]['text'], 'Knaagdieren');
      expect(categories[2]['text'], 'Roofdieren');
      expect(categories[0]['icon'], 'circle_icon:pets');
    });

    test('should filter items by category', () {
      // Arrange
      final items = ['Apple', 'Banana', 'Cherry'];
      filterFunction(String item, String category) => item.startsWith(category);
      
      // Act
      final filteredItems = filterManager.filterByCategory(items, 'A', filterFunction);
      
      // Assert
      expect(filteredItems.length, 1);
      expect(filteredItems[0], 'Apple');
    });

    test('should return all items when category is empty', () {
      // Arrange
      final items = ['Apple', 'Banana', 'Cherry'];
      filterFunction(String item, String category) => item.startsWith(category);
      
      // Act
      final filteredItems = filterManager.filterByCategory(items, '', filterFunction);
      
      // Assert
      expect(filteredItems.length, 3);
    });

    test('should sort items alphabetically', () {
      // Arrange
      final items = ['Zebra', 'Apple', 'Cherry'];
      
      // Act
      final sortedItems = (filterManager as FilterManager).sortAlphabetically(
        items,
        (item) => item.toLowerCase(),
      );
      
      // Assert
      expect(sortedItems[0], 'Apple');
      expect(sortedItems[1], 'Cherry');
      expect(sortedItems[2], 'Zebra');
    });

    test('should sort items by most viewed', () {
      // Arrange
      final items = [
        {'name': 'Item1', 'views': 5},
        {'name': 'Item2', 'views': 10},
        {'name': 'Item3', 'views': 2},
      ];
      
      // Act
      final sortedItems = (filterManager as FilterManager).sortByMostViewed(
        items,
        (item) => item['views'] as int,
      );
      
      // Assert
      expect(sortedItems[0]['name'], 'Item2'); // 10 views
      expect(sortedItems[1]['name'], 'Item1'); // 5 views
      expect(sortedItems[2]['name'], 'Item3'); // 2 views
    });

    test('should search animals by name', () {
      // Arrange
      final animals = [
        AnimalModel(animalId: '1', animalName: 'Wolf', animalImagePath: 'path1', genderViewCounts: []),
        AnimalModel(animalId: '2', animalName: 'Red Wolf', animalImagePath: 'path2', genderViewCounts: []),
        AnimalModel(animalId: '3', animalName: 'Fox', animalImagePath: 'path3', genderViewCounts: []),
      ];
      
      // Act
      final searchResults = filterManager.searchAnimals(animals, 'wolf');
      
      // Assert
      expect(searchResults.length, 2);
      expect(searchResults[0].animalName, 'Wolf');
      expect(searchResults[1].animalName, 'Red Wolf');
    });

    test('should return all animals when search term is empty', () {
      // Arrange
      final animals = [
        AnimalModel(animalId: '1', animalName: 'Wolf', animalImagePath: 'path1', genderViewCounts: []),
        AnimalModel(animalId: '2', animalName: 'Fox', animalImagePath: 'path2', genderViewCounts: []),
      ];
      
      // Act
      final searchResults = filterManager.searchAnimals(animals, '');
      
      // Assert
      expect(searchResults.length, 2);
    });

    test('should handle case-insensitive search', () {
      // Arrange
      final animals = [
        AnimalModel(animalId: '1', animalName: 'Wolf', animalImagePath: 'path1', genderViewCounts: []),
        AnimalModel(animalId: '2', animalName: 'Fox', animalImagePath: 'path2', genderViewCounts: []),
      ];
      
      // Act
      final searchResults = filterManager.searchAnimals(animals, 'WOLF');
      
      // Assert
      expect(searchResults.length, 1);
      expect(searchResults[0].animalName, 'Wolf');
    });
  });
}