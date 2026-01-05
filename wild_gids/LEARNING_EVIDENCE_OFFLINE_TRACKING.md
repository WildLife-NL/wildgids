# Learning Evidence: Offline Location Tracking

## What

Our app lets users track their location while using WildRapport, even when they don't have an internet connection. For each tracking session, we need to store location readings with their exact timestamps.

The backend API requires, for every location reading, three things:

- **location** ( `latitude` , `longitude` )
- **timestamp** ( ISO8601 UTC format )
- **immediate sending OR caching** ( when offline )

Before, the app didn't properly store location readings when offline. To fix that, I added offline caching support with three new components: `TrackingReading` model, `TrackingCacheManager`, and integration with `MapProvider`.

**📸 SCREENSHOT 1: Show the `TrackingReading` class in `lib/models/beta_models/tracking_reading_model.dart`**
- Highlight the three fields: `latitude`, `longitude`, `timestampUtc`
- Show the `toJson()` and `fromJson()` methods

```dart
class TrackingReading {
  final double latitude;
  final double longitude;
  final DateTime timestampUtc;

  TrackingReading({
    required this.latitude,
    required this.longitude,
    required this.timestampUtc,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'timestampUtc': timestampUtc.toIso8601String(),
      };

  factory TrackingReading.fromJson(Map<String, dynamic> json) {
    return TrackingReading(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestampUtc: DateTime.parse(json['timestampUtc'] as String),
    );
  }
}
```

In plain terms:

One `TrackingReading` = "GPS coordinates at a specific moment in time."

Example: "User was at (52.0, 5.0) at 2025-11-20T12:00:00Z" becomes one cached entry.

---

## Why

We needed this offline caching for three reasons:

### 1. The backend is strict.

The API expects tracking readings to be sent with the **exact timestamp** when the location was captured. If we only send the current location when internet reconnects, we lose the movement history. The backend needs to know "where was the user at 12:00, 12:10, 12:20" - not just "where are they now."

**📸 SCREENSHOT 2: Show the `tracking_api.dart` file where the request body is built**
- Highlight the `timestampUtc.toUtc().toIso8601String()` part
- Show the comment explaining the API format

```dart
final body = {
  "location": {"latitude": lat, "longitude": lon},
  "timestamp": timestampUtc.toUtc().toIso8601String(),
};
```

### 2. The old implementation lost important data.

We used to only send tracking readings when online. If the user went offline for 5 minutes (= 30 location readings at 10-second intervals), all those readings were lost. That doesn't give accurate tracking data. The backend needs the complete path.

### 3. The backend wants individual readings, not just totals.

The API doesn't accept "count: 5". It wants 5 separate location objects with their individual timestamps.

With `TrackingReading` and the cache manager, we can store each reading separately and send them all when connection returns.

**📸 SCREENSHOT 3: Show the `sendCachedReadings()` method in `tracking_cache_manager.dart`**
- Highlight the loop that sends each cached reading individually
- Show the debug logs that track success/failure per reading

```dart
for (int i = 0; i < cachedReadings.length; i++) {
  TrackingReading reading = cachedReadings[i];
  debugPrint('$yellowLog[TrackingCacheManager] Sending cached reading ${i + 1}/${cachedReadings.length}: $reading');
  
  try {
    await trackingApi.addTrackingReading(
      lat: reading.latitude,
      lon: reading.longitude,
      timestampUtc: reading.timestampUtc,
    );
    successCount++;
    debugPrint('$greenLog[TrackingCacheManager] Reading ${i + 1} sent successfully');
  } catch (e) {
    debugPrint('$redLog[TrackingCacheManager] Reading ${i + 1} failed: $e');
    failedReadings.add(reading);
  }
}
```

So this caching system lets the app collect the right info and speak the backend's language.

---

## How

### 1. In the Data Model

I created a new model class `TrackingReading` that stores one location reading:

**📸 SCREENSHOT 4: Show the complete `TrackingReading` class with the toString() method**

```dart
class TrackingReading {
  final double latitude;
  final double longitude;
  final DateTime timestampUtc;

  TrackingReading({
    required this.latitude,
    required this.longitude,
    required this.timestampUtc,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'timestampUtc': timestampUtc.toIso8601String(),
      };

  factory TrackingReading.fromJson(Map<String, dynamic> json) {
    return TrackingReading(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestampUtc: DateTime.parse(json['timestampUtc'] as String),
    );
  }

  @override
  String toString() {
    return 'TrackingReading(lat: $latitude, lon: $longitude, time: ${timestampUtc.toIso8601String()})';
  }
}
```

This model can be:
- Converted to/from JSON for storage
- Stored in SharedPreferences
- Sent to the API

### 2. In the Cache Manager

The manager ( `TrackingCacheManager` ) handles all the caching logic:

**📸 SCREENSHOT 5: Show the `cacheReading()` method**
- Highlight how it retrieves existing cached readings
- Show how it adds the new reading to the list
- Show the SharedPreferences save operation

```dart
Future<void> cacheReading(TrackingReading reading) async {
  try {
    debugPrint('$yellowLog[TrackingCacheManager] Caching tracking reading: $reading');
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? cachedJson = prefs.getStringList(_cacheKey);
    
    List<TrackingReading> readings = [];
    if (cachedJson != null) {
      readings = cachedJson
          .map((json) => TrackingReading.fromJson(jsonDecode(json)))
          .toList();
    }
    
    readings.add(reading);
    
    List<String> updatedJson = readings
        .map((reading) => jsonEncode(reading.toJson()))
        .toList();
    
    await prefs.setStringList(_cacheKey, updatedJson);
    
    debugPrint('$greenLog[TrackingCacheManager] Cached reading successfully. Total cached: ${readings.length}');
  } catch (e, stackTrace) {
    debugPrint('$redLog[TrackingCacheManager] Failed to cache reading: $e');
    debugPrint('$redLog$stackTrace');
    rethrow;
  }
}
```

The manager keeps all cached readings in SharedPreferences under the key `'cached_tracking_readings'`.

**📸 SCREENSHOT 6: Show the `sendOrCacheReading()` method**
- Highlight the internet connection check
- Show the try-catch that caches on failure

```dart
Future<TrackingNotice?> sendOrCacheReading({
  required double lat,
  required double lon,
  required DateTime timestampUtc,
}) async {
  debugPrint('$yellowLog[TrackingCacheManager] Attempting to send tracking reading');
  
  // Check if we have internet connection
  bool hasConnection = await ConnectionChecker.hasInternetConnection();
  
  if (!hasConnection) {
    debugPrint('$yellowLog[TrackingCacheManager] No internet connection, caching reading');
    await cacheReading(TrackingReading(
      latitude: lat,
      longitude: lon,
      timestampUtc: timestampUtc,
    ));
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
    
    await cacheReading(TrackingReading(
      latitude: lat,
      longitude: lon,
      timestampUtc: timestampUtc,
    ));
    
    return null;
  }
}
```

### 3. In the App Integration

I wired it into `main.dart`:

**📸 SCREENSHOT 7: Show the initialization in `main.dart`**
- Highlight the trackingApi creation
- Show the trackingCacheManager creation
- Show the init() call and setTrackingCacheManager() call

```dart
final trackingApi = TrackingApi(apiClient);
final trackingCacheManager = TrackingCacheManager(trackingApi: trackingApi);
trackingCacheManager.init();
mapProvider.setTrackingCacheManager(trackingCacheManager);
```

And modified `MapProvider` to use the cache manager:

**📸 SCREENSHOT 8: Show the `sendTrackingPingFromPosition()` method in `map_provider.dart`**
- Highlight the check for _trackingCacheManager
- Show the call to sendOrCacheReading()
- Show the fallback to direct API call

```dart
Future<TrackingNotice?> sendTrackingPingFromPosition(Position pos) async {
  // Prefer using the cache manager if available
  if (_trackingCacheManager != null) {
    debugPrint('[MapProvider] 📍 Sending tracking ping via cache manager: ${pos.latitude}, ${pos.longitude}');
    
    try {
      final notice = await _trackingCacheManager!.sendOrCacheReading(
        lat: pos.latitude,
        lon: pos.longitude,
        timestampUtc: DateTime.now().toUtc(),
      );

      if (notice != null) {
        _lastTrackingNotice = notice;
        notifyListeners();
      }
      return notice;
    } catch (e) {
      debugPrint('[MapProvider] ❌ tracking-reading failed: $e');
      return null;
    }
  }
  
  // Fallback to direct API call if cache manager not available
  // ... (rest of fallback code)
}
```

### 4. Connectivity Monitoring

The cache manager automatically monitors connectivity:

**📸 SCREENSHOT 9: Show the `init()` and `_handleConnectivityChange()` methods**
- Highlight the connectivity subscription
- Show how it triggers sending cached readings when online

```dart
void init() {
  if (_isInitialized) return;
  
  _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
    _handleConnectivityChange,
  );
  _isInitialized = true;
}

void _handleConnectivityChange(List<ConnectivityResult> results) async {
  debugPrint('$yellowLog[TrackingCacheManager] Connectivity changed: $results');

  final hasConnection = results.any((r) => r != ConnectivityResult.none);

  if (hasConnection) {
    debugPrint('$greenLog[TrackingCacheManager] Connection restored, trying to send cached readings');
    await _trySendCachedReadings();
  } else {
    debugPrint('$yellowLog[TrackingCacheManager] No internet connection – tracking readings will be cached');
  }
}
```

### 5. Testing

I wrote comprehensive unit tests to verify the behavior:

**📸 SCREENSHOT 10: Show the test file `tracking_cache_manager_test.dart`**
- Show the test names and structure
- Highlight one or two key tests

**📸 SCREENSHOT 11: Run the tests and show the output**
- Run: `flutter test test/business/tracking_cache_manager_test.dart`
- Show all 7 tests passing

```dart
test('should cache a tracking reading', () async { ... });
test('should send cached readings when connection is available', () async { ... });
test('should keep failed readings in cache', () async { ... });
test('should send reading immediately when connection is available', () async { ... });
test('should cache reading when API fails', () async { ... });
test('should cache reading when no internet connection', () async { ... });
test('should handle multiple cached readings correctly', () async { ... });
```

---

## Final API Payload

Right before we send to `/tracking-reading/`, the payload looks like:

**📸 SCREENSHOT 12: Show example from debug logs or the TrackingApi code**

```json
=== Final API Payload ===
{
  "location": {
    "latitude": 52.0,
    "longitude": 5.0
  },
  "timestamp": "2025-11-20T12:00:00.000Z"
}

POST: https://api-wildlifenl.uu.nl/tracking-reading/
[TrackingApi] Response code: 200
```

The server responds with HTTP 200, so the format is correct.

---

## Flow Diagram

**📸 SCREENSHOT 13: Create a simple flow diagram (can be hand-drawn or using draw.io) showing:**

```
User Location Tracked (every 10 seconds)
           ↓
    Has Internet? 
    ↙           ↘
  YES            NO
   ↓              ↓
Send to API    Cache to SharedPreferences
   ↓              ↓
Success?       Wait for connection
   ↓              ↓
   ✓          Connection restored
                  ↓
              Send all cached readings
                  ↓
              Remove from cache
```

---

## Real-World Example

**Scenario:** User goes offline for 50 seconds while location tracking is enabled.

**📸 SCREENSHOT 14: Show the kaart_overview_screen.dart line where tracking interval is set**

```dart
map.startTracking(interval: const Duration(seconds: 10));
```

**What happens:**
- **0s**: Location reading 1 → cached (52.0000, 5.0000, 2025-11-20T12:00:00Z)
- **10s**: Location reading 2 → cached (52.0001, 5.0001, 2025-11-20T12:00:10Z)
- **20s**: Location reading 3 → cached (52.0002, 5.0002, 2025-11-20T12:00:20Z)
- **30s**: Location reading 4 → cached (52.0003, 5.0003, 2025-11-20T12:00:30Z)
- **40s**: Location reading 5 → cached (52.0004, 5.0004, 2025-11-20T12:00:40Z)

**When internet returns:**
- All 5 readings sent in order with original timestamps
- Cache cleared
- Normal tracking continues

**📸 SCREENSHOT 15: Show debug logs from a real test**
- Show the caching logs (yellow)
- Show the sending logs (green)
- Show the "cache cleared" message

---

## Summary

This implementation ensures that:
✅ Location tracking works offline
✅ Original timestamps are preserved
✅ Complete movement history is captured
✅ Data automatically syncs when connection returns
✅ Failed readings are retried
✅ Cache persists across app restarts

The system follows the same pattern as the existing `ResponseManager` for consistency with the WildRapport codebase.
