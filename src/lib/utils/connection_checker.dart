import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectionChecker {
  static Future<bool> Function([int?]) _hasInternetConnectionImpl =
      _defaultHasInternetConnection;

  static Future<bool> _defaultHasInternetConnection([int? amount]) async {
    try {
      // First, check connectivity_plus plugin result
      final connectivityResult = await Connectivity().checkConnectivity();
      final hasConnectivity = connectivityResult.any((r) => r != ConnectivityResult.none);
      
      debugPrint('[ConnectionChecker] 🔌 Connectivity result: $connectivityResult (hasConnection: $hasConnectivity)');
      
      if (!hasConnectivity) {
        debugPrint('[ConnectionChecker] ❌ No connectivity detected');
        return false;
      }
      
      // For web/browser environments, connectivity_plus should be sufficient
      // Don't try external HTTP requests which will fail due to CORS
      debugPrint('[ConnectionChecker] ✅ Connectivity check passed - assuming internet available');
      return true;
      
    } catch (e) {
      debugPrint('[ConnectionChecker] ❌ Exception: $e');
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
