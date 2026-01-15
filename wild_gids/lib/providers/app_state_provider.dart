import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wildgids/managers/map/location_map_manager.dart';
import 'package:wildgids/models/beta_models/sighting_report_model.dart';
import 'package:wildgids/models/enums/report_type.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wildgids/constants/mock_location.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildgids/screens/login/login_screen.dart';

class AppStateProvider with ChangeNotifier {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final Map<String, Map<String, dynamic>> _screenStates = {};
  final Map<String, dynamic> _activeReports = {};
  ReportType? _currentReportType;
  Position? _cachedPosition;
  String? _cachedAddress;
  DateTime? _lastLocationUpdate;
  static const Duration locationCacheTimeout = Duration(minutes: 15);

  // Location tracking preference
  bool _isLocationTrackingEnabled = false;
  bool get isLocationTrackingEnabled => _isLocationTrackingEnabled;

  ReportType? get currentReportType => _currentReportType;
  Position? get cachedPosition => _cachedPosition;
  String? get cachedAddress => _cachedAddress;
  DateTime? get lastLocationUpdate => _lastLocationUpdate;

  bool get isLocationCacheValid {
    if (_lastLocationUpdate == null || _cachedPosition == null) {
      debugPrint(
        '\x1B[33m[AppStateProvider] Cache invalid: No cached data\x1B[0m',
      );
      return false;
    }

    final isValid =
        DateTime.now().difference(_lastLocationUpdate!) < locationCacheTimeout;
    debugPrint(
      '\x1B[36m[AppStateProvider] Cache status: ${isValid ? "valid" : "expired"}'
      ' (Age: ${DateTime.now().difference(_lastLocationUpdate!).inMinutes}m)\x1B[0m',
    );
    return isValid;
  }

  void setScreenState(String screenName, String key, dynamic value) {
    if (value == null) {
      debugPrint('Warning: Null value being set for $screenName.$key');
      return;
    }

    if (_screenStates[screenName]?.containsKey(key) ?? false) {
      final existingType = _screenStates[screenName]![key].runtimeType;
      if (value.runtimeType != existingType) {
        debugPrint(
          'Warning: Type mismatch for $screenName.$key. Expected $existingType, got ${value.runtimeType}',
        );
        return;
      }

      // Only notify if the value actually changed
      if (_screenStates[screenName]![key] != value) {
        _screenStates[screenName]![key] = value;
        notifyListeners();
      }
    } else {
      _screenStates[screenName] ??= {};
      _screenStates[screenName]![key] = value;
      notifyListeners();
    }
  }

  T? getScreenState<T>(String screenName, String key) {
    return _screenStates[screenName]?[key] as T?;
  }

  void clearScreenState(String screenName) {
    _screenStates.remove(screenName);
    notifyListeners();
  }

  void initializeReport(ReportType reportType) {
    debugPrint(
      '\x1B[36m[AppStateProvider] ðŸ”· Initializing report with type: $reportType\x1B[0m',
    );
    _currentReportType = reportType;
    final report = SightingReport(
      animals: [],
      systemDateTime: DateTime.now(),
    );

    _activeReports['currentReport'] = report;
    debugPrint(
      '\x1B[36m[AppStateProvider] ðŸ”· Report initialized. Current type: $_currentReportType\x1B[0m',
    );
    notifyListeners();
  }

  T? getCurrentReport<T>() {
    return _activeReports['currentReport'] as T?;
  }

  void updateCurrentReport(String property, dynamic value) {
    final report = _activeReports['currentReport'];
    if (report != null) {
      report.updateProperty(property, value);
      notifyListeners();
    }
  }

  void resetApplicationState(BuildContext context, {Widget? destination}) {
    _screenStates.clear();
    _activeReports.clear();
    _currentReportType = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _screenStates.clear();
    super.dispose();
  }

  Future<void> updateLocationCache() async {
    try {
      final position = MockLocation.enabled
          ? MockLocation.position()
          : await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
                timeLimit: Duration(seconds: 5),
              ),
            );

      final locationService = LocationMapManager();
      final address = await locationService.getAddressFromPosition(position);

      _cachedPosition = position;
      _cachedAddress = address;
      _lastLocationUpdate = DateTime.now();

      debugPrint(
        '\x1B[32m[AppStateProvider] Location cache updated successfully:'
        ' ${position.latitude}, ${position.longitude}\x1B[0m',
      );
      notifyListeners();
    } catch (e) {
      debugPrint(
        '\x1B[31m[AppStateProvider] Error updating location cache: $e\x1B[0m',
      );
    }
  }

  void startLocationUpdates() {
    Timer.periodic(locationCacheTimeout, (_) => updateLocationCache());
  }

  /// Load location tracking preference from SharedPreferences
  Future<void> loadLocationTrackingPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
        _isLocationTrackingEnabled =
          prefs.getBool('location_tracking_enabled') ?? false;
      debugPrint(
        '[AppStateProvider] Loaded location tracking preference: $_isLocationTrackingEnabled',
      );
      notifyListeners();
    } catch (e) {
      debugPrint(
        '[AppStateProvider] Failed to load location tracking preference: $e',
      );
      _isLocationTrackingEnabled = false; // Default to disabled
    }
  }

  /// Toggle location tracking on/off
  Future<void> setLocationTrackingEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('location_tracking_enabled', enabled);
      _isLocationTrackingEnabled = enabled;
      debugPrint(
        '[AppStateProvider] Location tracking ${enabled ? "enabled" : "disabled"}',
      );
      notifyListeners();
    } catch (e) {
      debugPrint(
        '[AppStateProvider] Failed to save location tracking preference: $e',
      );
    }
  }

  Future<void> logout() async {
    // Remove persisted auth/session
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('bearer_token');
    } catch (e, st) {
      debugPrint('[AppStateProvider] logout(): failed to clear token: $e\n$st');
    }

    // Reset in-memory app state
    _screenStates.clear();
    _activeReports.clear();
    _currentReportType = null;
    _cachedPosition = null;
    _cachedAddress = null;
    _lastLocationUpdate = null;
    notifyListeners();

    // Navigate to LoginScreen & clear back stack
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> deleteProfile() async {
    // This method is called from ProfileScreen after user confirms deletion.
    // Reset in-memory app state first
    _screenStates.clear();
    _activeReports.clear();
    _currentReportType = null;
    _cachedPosition = null;
    _cachedAddress = null;
    _lastLocationUpdate = null;
    notifyListeners();

    // Remove persisted auth/session
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('bearer_token');
    } catch (e, st) {
      debugPrint('[AppStateProvider] deleteProfile(): failed to clear token: $e\n$st');
    }

    // Navigate to LoginScreen & clear back stack
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}

