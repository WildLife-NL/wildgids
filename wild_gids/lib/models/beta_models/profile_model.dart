class Profile {
  String userID;
  String email;
  String? gender;
  String userName;
  String? postcode;
  bool? reportAppTerms;
  bool? recreationAppTerms;

  Profile({
    required this.userID,
    required this.email,
    this.gender,
    required this.userName,
    this.postcode,
    this.reportAppTerms,
    this.recreationAppTerms,
  });
  Map<String, dynamic> toJson() => {
    'ID': userID,
    'email': email,
    'gender': gender,
    'name': userName,
    'postcode': postcode,
    'reportAppTerms': reportAppTerms,
    'recreationAppTerms': recreationAppTerms,
  };
  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    userID: json['ID'],
    email: json['email'],
    gender: json['gender'],
    userName: json['name'],
    postcode: json['postcode'],
    reportAppTerms: json['reportAppTerms'],
    recreationAppTerms: json['recreationAppTerms'],
  );
}
