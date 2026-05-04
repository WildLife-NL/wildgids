import 'package:flutter/material.dart';
import 'package:wildgids/models/api_models/user.dart';

abstract class LoginInterface {
  /// Validates email format and returns error message if invalid, null if valid
  String? validateEmail(String? email);

  /// Resends verification code
  Future<bool> resendCode(String email);

  /// Verifies the code and returns user data
  Future<User> verifyCode(String email, String code);

  /// Sends initial login code
  Future<bool> sendLoginCode(String email);

  /// Shows or hides verification screen
  void setVerificationVisible(bool visible);

  /// Sets error state and message
  void setError(bool isError, [String message = '']);

  /// Add listener for state changes
  void addListener(VoidCallback listener);

  /// Remove listener for state changes
  void removeListener(VoidCallback listener);
}

