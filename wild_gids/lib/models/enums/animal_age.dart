enum AnimalAge {
  pasGeboren,
  onvolwassen,
  jong,
  volwassen,
  onbekend;

  String get displayText {
    switch (this) {
      case AnimalAge.pasGeboren:
        return 'Pas Geboren';
      case AnimalAge.onvolwassen:
        return 'Onvolwassen';
      case AnimalAge.jong:
        return 'Jong';
      case AnimalAge.volwassen:
        return 'Volwassen';
      case AnimalAge.onbekend:
        return 'Onbekend';
    }
  }
}
