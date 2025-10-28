enum ReportType {
  waarneming,
  gewasschade,
  verkeersongeval;

  String get displayText {
    switch (this) {
      case ReportType.waarneming:
        return 'Waarneming';
      case ReportType.gewasschade:
        return 'Gewasschade';
      case ReportType.verkeersongeval:
        return 'Verkeersongeval';
    }
  }
}
