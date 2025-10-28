enum LocationType {
  current,
  npZuidKennemerland,
  grensparkKempenbroek,
  unknown;

  String get displayText {
    switch (this) {
      case LocationType.current:
        return 'Huidige locatie';
      case LocationType.npZuidKennemerland:
        return 'Zuid-Kennemerland';
      case LocationType.grensparkKempenbroek:
        return 'Grenspark KempenBroek';
      case LocationType.unknown:
        return 'Onbekend';
    }
  }

  String get iconPath {
    switch (this) {
      case LocationType.current:
        return 'circle_icon:my_location';
      case LocationType.npZuidKennemerland:
        return 'circle_icon:forest';
      case LocationType.grensparkKempenbroek:
        return 'circle_icon:nature';
      case LocationType.unknown:
        return 'circle_icon:close';
    }
  }
}
