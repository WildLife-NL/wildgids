class DateTimeModel {
  final DateTime? dateTime;
  final String? userSelectedDate;
  final String? userSelectedTime;

  DateTimeModel({
    this.dateTime,
    this.userSelectedDate,
    this.userSelectedTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'dateTime': dateTime?.toIso8601String(),
      'userSelectedDate': userSelectedDate,
      'userSelectedTime': userSelectedTime,
    };
  }

  factory DateTimeModel.fromJson(Map<String, dynamic> json) {
    return DateTimeModel(
      dateTime: json['dateTime'] != null ? DateTime.parse(json['dateTime']) : null,
      userSelectedDate: json['userSelectedDate'],
      userSelectedTime: json['userSelectedTime'],
    );
  }

  DateTimeModel copyWith({
    DateTime? dateTime,
    String? userSelectedDate,
    String? userSelectedTime,
  }) {
    return DateTimeModel(
      dateTime: dateTime ?? this.dateTime,
      userSelectedDate: userSelectedDate ?? this.userSelectedDate,
      userSelectedTime: userSelectedTime ?? this.userSelectedTime,
    );
  }
}
