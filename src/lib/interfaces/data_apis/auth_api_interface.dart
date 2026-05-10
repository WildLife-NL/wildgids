import 'package:wildgids/models/api_models/user.dart';

abstract class AuthApiInterface {
  Future<Map<String, dynamic>> authenticate(
    String displayNameApp,
    String email,
  );
  Future<User> authorize(String email, String code);
}

