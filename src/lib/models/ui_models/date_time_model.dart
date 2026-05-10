class DateTimeModel {
  final DateTime? dateTime;
  final bool isUnknown;

  DateTimeModel({this.dateTime, this.isUnknown = false});

  Map<String, dynamic> toJson() {
    return {'dateTime': dateTime?.toIso8601String(), 'isUnknown': isUnknown};
  }

  factory DateTimeModel.fromJson(Map<String, dynamic> json) {
    return DateTimeModel(
      dateTime:
          json['dateTime'] != null ? DateTime.parse(json['dateTime']) : null,
      isUnknown: json['isUnknown'] ?? false,
    );
  }
}
