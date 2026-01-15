import 'package:shared_preferences/shared_preferences.dart';

/// Validates authentication tokens stored in SharedPreferences
///
/// This class handles "stay logged in" functionality:
/// - When user logs in successfully, token is stored in SharedPreferences
/// - App checks for valid token on startup to keep user logged in
/// - Token persists until user explicitly logs out or uninstalls the app
/// - On mobile, uninstalling the app automatically clears SharedPreferences
class TokenValidator {
  /// Checks if a valid authentication token exists
  ///
  /// Returns true if user should stay logged in, false otherwise.
  /// This enables "stay logged in" behavior across app restarts.
  static Future<bool> hasValidToken() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if token exists in SharedPreferences
    final token = prefs.getString('bearer_token');

    // Return true if token exists (user stays logged in)
    // Return false if no token (user needs to log in)
    return token != null && token.isNotEmpty;
  }

  /// Clears the authentication token (for logout)
  ///
  /// Call this when user explicitly logs out.
  /// App uninstallation automatically clears tokens.
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('bearer_token');
  }
}
