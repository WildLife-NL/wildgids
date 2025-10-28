enum FilterType {
  none('Filteren', 'circle_icon:filter_list'),
  alphabetical('Alfabetisch', 'circle_icon:sort_by_alpha'),
  mostViewed('Meest bekeken', 'circle_icon:visibility'),
  search('Zoeken', 'circle_icon:search');

  final String displayText;
  final String iconPath;

  const FilterType(this.displayText, this.iconPath);
}
