enum DateTimeType {
  current,
  custom,
  unknown;

  String get displayText {
    switch (this) {
      case DateTimeType.current:
        return 'Nu';
      case DateTimeType.custom:
        return 'Kies datum & tijd';
      case DateTimeType.unknown:
        return 'Onbekend';
    }
  }

  String get iconPath {
    switch (this) {
      case DateTimeType.current:
        return 'circle_icon:schedule';
      case DateTimeType.custom:
        return 'circle_icon:calendar_today';
      case DateTimeType.unknown:
        return 'circle_icon:help';
    }
  }
}
