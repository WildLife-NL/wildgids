class User {
  final String id;
  final String? email;
  String? name;

  final bool? reportAppTerms;

  User({required this.id, required this.email, this.name, this.reportAppTerms});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['userID'] ?? "",
      email: json['email'] ?? "",
      name: json['name'] ?? "",
      reportAppTerms: json['reportAppTerms'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'email': email, 'name': name};
  }

    Map<String, dynamic> toTermsUpdateJson() {
    return {
      if (reportAppTerms != null) 'reportAppTerms': reportAppTerms,
    };
  }
}


