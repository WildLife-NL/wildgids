enum AnimalCondition {
  gezond,
  gewond,
  dood,
  andere;

  String get displayText {
    switch (this) {
      case AnimalCondition.gezond:
        return 'Gezond';
      case AnimalCondition.gewond:
        return 'Gewond';
      case AnimalCondition.dood:
        return 'Dood';
      case AnimalCondition.andere:
        return 'Andere';
    }
  }
}
