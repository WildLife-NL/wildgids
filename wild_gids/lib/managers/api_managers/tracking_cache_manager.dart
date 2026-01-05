import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:wildrapport/interfaces/data_apis/tracking_api_interface.dart';
import 'package:wildrapport/models/beta_models/tracking_reading_model.dart';
import 'package:wildrapport/utils/connection_checker.dart';

/// Manages caching of location tracking readings when offline,
/// and automatically retries sending them when connection is restored.
class TrackingCacheManager {
  static const String _cacheKey = 'cached_tracking_readings';

  final TrackingApiInterface trackingApi;
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _isRetryingSend = false;
  bool _isInitialized = false;

  final String greenLog = '\x1B[32m';
  final String redLog = '\x1B[31m';
  final String yellowLog = '\x1B[93m';

  TrackingCacheManager({required this.trackingApi, Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  /// Initialize connectivity monitoring
  void init() {
    if (_isInitialized) return;

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _handleConnectivityChange,
    );
    _isInitialized = true;
  }

  /// Clean up resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _isInitialized = false;
  }

  /// Handle connectivity changes - try to send cached data when connection is restored
  void _handleConnectivityChange(List<ConnectivityResult> results) async {
    debugPrint(
      '$yellowLog[TrackingCacheManager] Connectivity changed: $results',
    );

    final hasConnection = results.any((r) => r != ConnectivityResult.none);

    if (hasConnection) {
      debugPrint(
        '$greenLog[TrackingCacheManager] Connection restored, trying to send cached readings',
      );
      await _trySendCachedReadings();
    } else {
      debugPrint(
        '$yellowLog[TrackingCacheManager] No internet connection – tracking readings will be cached',
      );
    }
  }

  /// Schedule retry loop until success
  void _scheduleRetryUntilSuccess() {
    if (_isRetryingSend) return;
    _isRetryingSend = true;

    _retryLoop();
  }

  /// Retry loop that checks connection periodically
  void _retryLoop() async {
    while (true) {
      bool hasConnection = await ConnectionChecker.hasInternetConnection();
      if (hasConnection) {
        try {
          await _trySendCachedReadings();
          debugPrint(
            '$greenLog[TrackingCacheManager] Successfully sent cached readings',
          );
          _isRetryingSend = false;
          break; // Stop retrying after success
        } catch (e) {
          debugPrint(
            '$yellowLog[TrackingCacheManager] Retry failed: $e. Will try again in 10 seconds.',
          );
        }
      } else {
        debugPrint(
          '$yellowLog[TrackingCacheManager] No internet. Will check again in 10 seconds.',
        );
      }
      await Future.delayed(Duration(seconds: 10));
    }
  }

  /// Try to send all cached readings
  Future<void> _trySendCachedReadings() async {
    if (!await ConnectionChecker.hasInternetConnection()) {
      debugPrint(
        '$yellowLog[TrackingCacheManager] Internet not fully ready. Retry later.',
      );
      _scheduleRetryUntilSuccess();
      return;
    }
    await sendCachedReadings();
  }

  /// Cache a tracking reading to local storage
  Future<void> cacheReading(TrackingReading reading) async {
    try {
      debugPrint(
        '$yellowLog[TrackingCacheManager] Caching tracking reading: $reading',
      );

      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String>? cachedJson = prefs.getStringList(_cacheKey);

      List<TrackingReading> readings = [];
      if (cachedJson != null) {
        readings =
            cachedJson
                .map((json) => TrackingReading.fromJson(jsonDecode(json)))
                .toList();
      }

      readings.add(reading);

      List<String> updatedJson =
          readings.map((reading) => jsonEncode(reading.toJson())).toList();

      await prefs.setStringList(_cacheKey, updatedJson);

      debugPrint(
        '$greenLog[TrackingCacheManager] Cached reading successfully. Total cached: ${readings.length}',
      );
    } catch (e, stackTrace) {
      debugPrint('$redLog[TrackingCacheManager] Failed to cache reading: $e');
      debugPrint('$redLog$stackTrace');
      rethrow;
    }
  }

  /// Get all cached readings
  Future<List<TrackingReading>> getCachedReadings() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String>? cachedJson = prefs.getStringList(_cacheKey);

      if (cachedJson == null || cachedJson.isEmpty) {
        return [];
      }

      return cachedJson
          .map((json) => TrackingReading.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      debugPrint(
        '$redLog[TrackingCacheManager] Failed to get cached readings: $e',
      );
      return [];
    }
  }

  /// Send all cached readings to the server
  Future<void> sendCachedReadings() async {
    debugPrint(
      '$yellowLog[TrackingCacheManager] === Starting sendCachedReadings ===',
    );

    List<TrackingReading> cachedReadings = await getCachedReadings();

    if (cachedReadings.isEmpty) {
      debugPrint('$yellowLog[TrackingCacheManager] No cached readings to send');
      return;
    }

    debugPrint(
      '$yellowLog[TrackingCacheManager] Found ${cachedReadings.length} cached readings to send',
    );

    // Use ConnectionChecker for testability
    debugPrint('$yellowLog[TrackingCacheManager] Checking internet connection...');
    final hasConnection = await ConnectionChecker.hasInternetConnection();

    if (!hasConnection) {
      debugPrint(
        '$yellowLog[TrackingCacheManager] No connection, keeping readings in cache',
      );
      return;
    }

    List<TrackingReading> failedReadings = [];
    int successCount = 0;

    for (int i = 0; i < cachedReadings.length; i++) {
      TrackingReading reading = cachedReadings[i];
      // Only log every 50 readings to reduce spam
      if ((i + 1) % 50 == 0 || i == 0 || i == cachedReadings.length - 1) {
        debugPrint(
          '$yellowLog[TrackingCacheManager] Progress: ${i + 1}/${cachedReadings.length} readings processed',
        );
      }

      try {
        await trackingApi.addTrackingReading(
          lat: reading.latitude,
          lon: reading.longitude,
          timestampUtc: reading.timestampUtc,
        );
        successCount++;
      } catch (e) {
        debugPrint('$redLog[TrackingCacheManager] Reading ${i + 1} failed: $e');
        failedReadings.add(reading);
      }
    }

    debugPrint('$yellowLog[TrackingCacheManager] === Send Summary ===');
    debugPrint(
      '$yellowLog[TrackingCacheManager] Total: ${cachedReadings.length}, '
      'Successful: $successCount, Failed: ${failedReadings.length}',
    );

    // Update cache with only failed readings
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (failedReadings.isEmpty) {
      await prefs.remove(_cacheKey);
      debugPrint(
        '$greenLog[TrackingCacheManager] All cached readings sent successfully and cache cleared',
      );
    } else {
      List<String> updatedJson =
          failedReadings
              .map((reading) => jsonEncode(reading.toJson()))
              .toList();
      await prefs.setStringList(_cacheKey, updatedJson);
      debugPrint(
        '$yellowLog[TrackingCacheManager] ${failedReadings.length} readings failed, kept in cache',
      );
    }
  }

  /// Attempt to send a tracking reading immediately, cache if it fails
  Future<TrackingNotice?> sendOrCacheReading({
    required double lat,
    required double lon,
    required DateTime timestampUtc,
  }) async {
    debugPrint(
      '$yellowLog[TrackingCacheManager] Attempting to send tracking reading',
    );

    // Check if we have internet connection
    bool hasConnection = await ConnectionChecker.hasInternetConnection();

    if (!hasConnection) {
      debugPrint(
        '$yellowLog[TrackingCacheManager] No internet connection, caching reading',
      );
      await cacheReading(
        TrackingReading(
          latitude: lat,
          longitude: lon,
          timestampUtc: timestampUtc,
        ),
      );
      return null;
    }

    // Try to send the reading
    try {
      final notice = await trackingApi.addTrackingReading(
        lat: lat,
        lon: lon,
        timestampUtc: timestampUtc,
      );
      debugPrint('$greenLog[TrackingCacheManager] Reading sent successfully');

      // If successful, try to send any cached readings too
      _trySendCachedReadings();

      return notice;
    } catch (e) {
      debugPrint('$redLog[TrackingCacheManager] Failed to send reading: $e');
      debugPrint('$yellowLog[TrackingCacheManager] Caching reading for later');

      await cacheReading(
        TrackingReading(
          latitude: lat,
          longitude: lon,
          timestampUtc: timestampUtc,
        ),
      );

      return null;
    }
  }
}
