enum AnimalGender {
  male,
  female,
  onbekend;

  String get displayText {
    switch (this) {
      case AnimalGender.male:
        return 'Mannelijk';
      case AnimalGender.female:
        return 'Vrouwelijk';
      case AnimalGender.onbekend:
        return 'Onbekend';
    }
  }
}
