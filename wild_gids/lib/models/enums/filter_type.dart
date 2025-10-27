enum FilterType {
  alphabetical,
  mostViewed;

  String get displayText {
    switch (this) {
      case FilterType.alphabetical:
        return 'Alfabetisch';
      case FilterType.mostViewed:
        return 'Meest Bekeken';
    }
  }
}
