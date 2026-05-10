class Profile {
  String userID;
  String email;
  String? gender;
  String userName;
  String? postcode;
  bool? reportAppTerms;
  bool? recreationAppTerms;
  String? dateOfBirth;
  String? description;
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
    this.description,
    this.location,
    this.locationTimestamp,
  });

  Map<String, dynamic> toJson() => {
    'ID': userID,
    'email': email,
    'gender': gender,
    'name': userName,
    'postcode': postcode,
    'reportAppTerms': reportAppTerms,
    'recreationAppTerms': recreationAppTerms,
    if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
    if (description != null) 'description': description,
    if (location != null) 'location': location,
    if (locationTimestamp != null) 'locationTimestamp': locationTimestamp,
  };

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    userID: json['ID'],
    email: json['email'],
    gender: json['gender'],
    userName: json['name'],
    postcode: json['postcode'],
    reportAppTerms: json['reportAppTerms'],
    recreationAppTerms: json['recreationAppTerms'],
    dateOfBirth: json['dateOfBirth'],
    description: json['description'],
    location: json['location'],
    locationTimestamp: json['locationTimestamp'],
  );
}
