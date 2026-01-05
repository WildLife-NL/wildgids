import 'package:flutter/material.dart';
import 'package:wildrapport/interfaces/data_apis/auth_api_interface.dart';
import 'package:wildrapport/interfaces/data_apis/profile_api_interface.dart';
import 'package:wildrapport/interfaces/other/login_interface.dart';
import 'package:wildrapport/models/ui_models/brown_button_model.dart';
import 'package:wildrapport/constants/app_colors.dart';
import 'package:wildrapport/models/api_models/user.dart';
import 'package:wildrapport/exceptions/validation_exception.dart';

class LoginManager implements LoginInterface {
  final AuthApiInterface authApi;
  final List<VoidCallback> _listeners = [];
  bool _showVerification = false;
  bool _isError = false;
  String _errorMessage = '';
  ProfileApiInterface profileApi;

  /// Constructor that initializes the login manager with authentication API
  LoginManager(this.authApi, this.profileApi);

  // Email validation regex
  static final _emailRegex = RegExp(
    r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$',
  );

  /// Validates an email address format
  /// Returns null if valid, or an error message if invalid
  @override
  String? validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return 'Voer een e-mailadres in';
    }
    if (!_emailRegex.hasMatch(email.trim())) {
      return 'Voer een geldig e-mailadres in';
    }
    return null;
  }

  /// Creates a button model with specified properties
  /// Uses different settings for login buttons (fontSize: 16) vs regular buttons
  static BrownButtonModel createButtonModel({
    required String text,
    String leftIconPath = '',
    String rightIconPath = '',
    bool isLoginButton = false,
  }) {
    if (isLoginButton) {
      return BrownButtonModel(
        text: text,
        leftIconPath: leftIconPath,
        rightIconPath: rightIconPath,
        fontSize: 16,
        elevation: 0,
        backgroundColor: AppColors.darkGreen,
      );
    }

    return BrownButtonModel(
      text: text,
      leftIconPath: leftIconPath,
      rightIconPath: rightIconPath,
    );
  }

  /// Sends a login code to the provided email
  /// Validates email first, then calls the auth API to send verification code
  /// Returns true on success, throws exception on failure
  @override
  Future<bool> sendLoginCode(String email) async {
    // Validate email first
    final validationError = validateEmail(email);
    if (validationError != null) {
      throw ValidationException(validationError);
    }

    try {
      await authApi.authenticate("Wild Gids", email.trim());
      return true;
    } catch (e) {
      throw Exception("Login failed: $e");
    }
  }

  /// Verifies the login code entered by the user
  /// Calls the auth API to verify the code and returns User data on success
  /// Throws specific exceptions based on error type
  @override
  Future<User> verifyCode(String email, String code) async {
    try {
      User response = await authApi.authorize(email, code);
      await profileApi.setProfileDataInDeviceStorage();
      return response;
    } catch (e, stackTrace) {
      debugPrint("[LoginManager]: ${e.toString()}");
      debugPrint("[LoginManager]: ${stackTrace.toString()}");
      // Handle specific error types
      if (e.toString().contains('Unauthorized') ||
          e.toString().contains('401')) {
        throw Exception("Invalid verification code");
      } else if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused')) {
        throw Exception("Network connection error");
      }
      throw Exception("Unhandled Unauthorized Exception");
    }
  }

  /// Resends the verification code to the provided email
  /// Validates email first, then calls the auth API to resend code
  /// Returns true on success, throws exception on failure
  @override
  Future<bool> resendCode(String email) async {
    final validationError = validateEmail(email);
    if (validationError != null) {
      throw ValidationException(validationError);
    }

    try {
      await authApi.authenticate("Wild Gids", email.trim());
      return true;
    } catch (e) {
      throw Exception("Resend code failed: $e");
    }
  }

  /// Sets the visibility state of the verification screen
  /// Updates the state and notifies listeners of the change
  @override
  void setVerificationVisible(bool visible) {
    _showVerification = visible;
    _notifyListeners();
  }

  /// Returns whether the verification screen is currently visible
  bool isVerificationVisible() => _showVerification;

  /// Returns whether there is currently an error state
  bool hasError() => _isError;

  /// Returns the current error message
  String getErrorMessage() => _errorMessage;

  /// Sets the error state and optional error message
  /// Updates the state and notifies listeners of the change
  @override
  void setError(bool isError, [String message = '']) {
    _isError = isError;
    _errorMessage = message;
    _notifyListeners();
  }

  /// Adds a listener callback that will be called when state changes
  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  /// Removes a previously added listener callback
  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  /// Notifies all registered listeners of state changes
  /// Called internally whenever state is updated
  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }
}
