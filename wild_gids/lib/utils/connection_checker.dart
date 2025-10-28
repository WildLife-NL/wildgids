import 'package:http/http.dart' as http;

class ConnectionChecker {
  static Future<bool> Function([int?]) _hasInternetConnectionImpl = _defaultHasInternetConnection;
  
  static Future<bool> _defaultHasInternetConnection([int? amount]) async {
    try {
      final response = await http
          .get(Uri.parse('https://clients3.google.com/generate_204'))
          .timeout(Duration(seconds: amount ?? 3));
      return response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }
  
  // Setter for testing
  static set setHasInternetConnection(Future<bool> Function([int?]) testImpl) {
    _hasInternetConnectionImpl = testImpl;
  }
  
  static Future<bool> hasInternetConnection([int? amount]) async {
    return _hasInternetConnectionImpl(amount);
  }
}


