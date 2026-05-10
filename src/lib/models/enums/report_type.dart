enum ReportType {
  waarneming;

  String get displayText {
    switch (this) {
      case ReportType.waarneming:
        return 'Waarneming';
    }
  }
}
