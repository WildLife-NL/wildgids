class Profile {
  String userID;
  String email;
  String? gender;
  String userName;
  String? postcode;
  bool? reportAppTerms;
  bool? recreationAppTerms;
  String? dateOfBirth;
  String? notes;
  int? natureVisitFrequency;
  String? firebaseCloudMessagingToken;
  Map<String, dynamic>? location;
  String? locationTimestamp;

  Profile({
    required this.userID,
    required this.email,
    this.gender,
    required this.userName,
    this.postcode,
    this.reportAppTerms,
    this.recreationAppTerms,
    this.dateOfBirth,
    this.notes,
    this.natureVisitFrequency,
    this.firebaseCloudMessagingToken,
    this.location,
    this.locationTimestamp,
  });

  /// Backwards compatibility for code that used `description`.
  String? get description => notes;

  static String? toApiDateOfBirth(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final trimmed = value.trim();
    if (trimmed.contains('T')) {
      return trimmed.split('T').first;
    }
    return trimmed;
  }

  Map<String, dynamic> toUpdateJson({String? firebaseCloudMessagingToken}) {
    final apiDateOfBirth = Profile.toApiDateOfBirth(dateOfBirth);
    return {
      'name': userName,
      'firebaseCloudMessagingToken': firebaseCloudMessagingToken,
      'natureVisitFrequency': natureVisitFrequency ?? 0,
      'reportAppTerms': reportAppTerms ?? false,
      'recreationAppTerms': recreationAppTerms ?? false,
      if (gender != null) 'gender': gender,
      if (postcode != null && postcode!.isNotEmpty) 'postcode': postcode,
      if (apiDateOfBirth != null) 'dateOfBirth': apiDateOfBirth,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }

  Map<String, dynamic> toJson() => {
        'ID': userID,
        'email': email,
        'gender': gender,
        'name': userName,
        'postcode': postcode,
        'reportAppTerms': reportAppTerms,
        'recreationAppTerms': recreationAppTerms,
        if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
        if (notes != null) 'notes': notes,
        if (natureVisitFrequency != null)
          'natureVisitFrequency': natureVisitFrequency,
        'firebaseCloudMessagingToken': firebaseCloudMessagingToken,
        if (location != null) 'location': location,
        if (locationTimestamp != null) 'locationTimestamp': locationTimestamp,
      };

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        userID: json['ID'] as String,
        email: json['email'] as String,
        gender: json['gender'] as String?,
        userName: json['name'] as String,
        postcode: json['postcode'] as String?,
        reportAppTerms: json['reportAppTerms'] as bool?,
        recreationAppTerms: json['recreationAppTerms'] as bool?,
        dateOfBirth: toApiDateOfBirth(json['dateOfBirth'] as String?),
        notes: (json['notes'] ?? json['description']) as String?,
        natureVisitFrequency: _parseNatureVisitFrequency(json),
        firebaseCloudMessagingToken:
            json['firebaseCloudMessagingToken'] as String?,
        location: json['location'] as Map<String, dynamic>?,
        locationTimestamp: json['locationTimestamp'] as String?,
      );

  static int? _parseNatureVisitFrequency(Map<String, dynamic> json) {
    final raw =
        json['natureVisitFrequency'] ?? json['natureVisitAvgWeeklyFrequency'];
    if (raw == null) return null;
    return (raw as num).toInt();
  }
}
