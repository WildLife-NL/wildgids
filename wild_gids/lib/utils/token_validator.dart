import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class TokenValidator {
  static Future<bool> hasValidToken() async {
    final prefs = await SharedPreferences.getInstance();
    
    // On mobile, always require fresh login
    if (!kIsWeb) {
      await prefs.remove('bearer_token');
      return false;
    }

    // Check if token exists
    final token = prefs.getString('bearer_token');
    return token != null;
  }
}
