import 'package:shared_preferences/shared_preferences.dart';

/// Bump this suffix when text changes and you want users to re-accept.
const String _termsKey = 'termsAccepted_v1';

Future<bool> isTermsAccepted() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_termsKey) ?? false;
}

Future<void> setTermsAccepted() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_termsKey, true);
}
