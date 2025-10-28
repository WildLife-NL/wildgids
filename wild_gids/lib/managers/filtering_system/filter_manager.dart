import 'package:wildrapport/interfaces/filters/filter_interface.dart';
import 'package:wildrapport/models/enums/filter_type.dart';
import 'package:wildrapport/models/ui_models/brown_button_model.dart';
import 'package:wildrapport/models/animal_waarneming_models/animal_model.dart';

//Animal screen filter dropdown logic handeling

class FilterManager implements FilterInterface {
  // List of filter options available in the animal screen
  static final List<BrownButtonModel> _filterOptions = [
    BrownButtonModel(
      text: FilterType.alphabetical.displayText,
      leftIconPath: 'circle_icon:sort_by_alpha',
      leftIconSize: 38.0,
      rightIconSize: 24.0,
      leftIconPadding: 5,
    ),
    BrownButtonModel(
      text: FilterType.mostViewed.displayText,
      leftIconPath: 'circle_icon:visibility',
      leftIconSize: 38.0,
      rightIconSize: 24.0,
      leftIconPadding: 5,
    ),
    BrownButtonModel(
      text: FilterType.search.displayText,
      leftIconPath: 'circle_icon:search',
      leftIconSize: 38.0,
      rightIconSize: 24.0,
      leftIconPadding: 5,
    ),
  ];

  /// Returns a list of available filter options based on the current filter
  /// If no filter is selected or the filter is 'Filteren', returns all options
  /// Otherwise, returns all options except the currently selected one
  @override
  List<BrownButtonModel> getAvailableFilters(String currentFilter) {
    if (currentFilter == FilterType.none.displayText ||
        currentFilter == 'Filteren' ||
        currentFilter.isEmpty) {
      return _filterOptions;
    }

    return _filterOptions
        .where((filter) => filter.text != currentFilter)
        .toList();
  }

  /// Filters animals alphabetically by name
  /// Places animals with name 'Onbekend' at the end of the list
  /// Uses sortAlphabetically method to sort the regular animals
  @override
  List<AnimalModel> filterAnimalsAlphabetically(List<AnimalModel> animals) {
    // Separate "Onbekend" from other animals
    final unknown =
        animals.where((animal) => animal.animalName == 'Onbekend').toList();
    final regularAnimals =
        animals.where((animal) => animal.animalName != 'Onbekend').toList();

    // Sort regular animals
    final sortedRegularAnimals = sortAlphabetically(
      regularAnimals,
      (animal) => animal.animalName.toLowerCase(),
    );

    // Combine sorted regular animals with unknown at the bottom
    return [...sortedRegularAnimals, ...unknown];
  }

  /// Returns a list of animal categories with their icons
  /// Each category is represented as a map with 'icon' and 'text' keys
  List<Map<String, String>> getAnimalCategories() {
    return [
      {
        'icon': 'circle_icon:pets',
        'text': 'Evenhoevigen',
      }, // Using Flutter icon
      {'icon': 'circle_icon:pets', 'text': 'Knaagdieren'}, // Using Flutter icon
      {'icon': 'circle_icon:pets', 'text': 'Roofdieren'}, // Using Flutter icon
    ];
  }

  /// Filters items by category using the provided filter function
  /// Returns all items if category is empty
  /// Otherwise returns only items that match the category according to the filter function
  @override
  List<T> filterByCategory<T>(
    List<T> items,
    String category,
    bool Function(T item, String category) filterFunction,
  ) {
    if (category.isEmpty) return items;
    return items.where((item) => filterFunction(item, category)).toList();
  }

  /// Sorts items alphabetically using the provided comparison string function
  /// Creates a new list from the input items and sorts it in place
  /// Returns the sorted list
  List<T> sortAlphabetically<T>(
    List<T> items,
    String Function(T item) getComparisonString,
  ) {
    return List<T>.from(
      items,
    )..sort((a, b) => getComparisonString(a).compareTo(getComparisonString(b)));
  }

  /// Sorts items by view count in descending order (most viewed first)
  /// Creates a new list from the input items and sorts it in place
  /// Uses the provided function to get the view count for each item
  List<T> sortByMostViewed<T>(
    List<T> items,
    int Function(T item) getViewCount,
  ) {
    return List<T>.from(items)
      ..sort((a, b) => getViewCount(b).compareTo(getViewCount(a)));
  }

  /// Searches animals by name using the provided search term
  /// Returns all animals if search term is empty
  /// Otherwise returns animals whose names contain the search term (case-insensitive)
  @override
  List<AnimalModel> searchAnimals(
    List<AnimalModel> animals,
    String searchTerm,
  ) {
    if (searchTerm.isEmpty) return animals;

    final searchTermLower = searchTerm.toLowerCase();
    return animals.where((animal) {
      final animalNameLower = animal.animalName.toLowerCase();
      return animalNameLower.contains(searchTermLower);
    }).toList();
  }
}
