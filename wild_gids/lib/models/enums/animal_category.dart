enum AnimalCategory {
  evenhoevigen,
  knaagdieren,
  roofdieren,
  andere;

  String get displayText {
    switch (this) {
      case AnimalCategory.evenhoevigen:
        return 'Evenhoevigen';
      case AnimalCategory.knaagdieren:
        return 'Knaagdieren';
      case AnimalCategory.roofdieren:
        return 'Roofdieren';
      case AnimalCategory.andere:
        return 'Andere';
    }
  }
}
