enum LocationType {
  current,
  custom;

  String get displayText {
    switch (this) {
      case LocationType.current:
        return 'Huidige locatie';
      case LocationType.custom:
        return 'Kies locatie op kaart';
    }
  }

  String get iconPath {
    switch (this) {
      case LocationType.current:
        return 'circle_icon:my_location';
      case LocationType.custom:
        return 'circle_icon:pin_drop';
    }
  }
}
