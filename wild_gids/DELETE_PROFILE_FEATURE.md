# Profile Deletion Feature Implementation

## Overview
This document outlines the implementation of the profile deletion feature for the Wild Gids application, which uses the WildlifeNL API endpoint `DELETE /profile/me/`.

## API Endpoint
- **Method**: DELETE
- **Endpoint**: `/profile/me/`
- **Authentication**: Bearer token (required)
- **Response**: 204 No Content on success

## Implementation Details

### 1. ProfileApiInterface (`lib/interfaces/data_apis/profile_api_interface.dart`)
**Added Method:**
```dart
Future<void> deleteMyProfile();
```
This abstract method defines the contract for profile deletion across all implementations.

### 2. ProfileApi (`lib/data_managers/profile_api.dart`)
**Implementation:**
```dart
@override
Future<void> deleteMyProfile() async {
  debugPrint('[ProfileApi] DELETE /profile/me/');

  final http.Response response = await client.delete(
    '/profile/me/',
    authenticated: true,
  );

  debugPrint('[ProfileApi] DELETE Response (${response.statusCode})');

  if (response.statusCode == HttpStatus.noContent) {
    // 204 No Content - Success
    debugPrint('$greenLog Profile successfully deleted!');
  } else if (response.statusCode == HttpStatus.ok) {
    // Some APIs return 200 OK instead of 204
    debugPrint('$greenLog Profile successfully deleted (200 OK)!');
  } else {
    throw Exception(
      "$redLog Failed to delete profile (${response.statusCode}): ${response.body}",
    );
  }
}
```

**Features:**
- Uses the existing `ApiClient.delete()` method with automatic bearer token authentication
- Handles both 204 No Content and 200 OK responses
- Includes debug logging for troubleshooting
- Throws meaningful exceptions on failure

### 3. AppStateProvider (`lib/providers/app_state_provider.dart`)
**New Method:**
```dart
Future<void> deleteProfile() async {
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
```

**Functionality:**
- Clears all in-memory app state (screen states, active reports, location data)
- Removes the bearer token from SharedPreferences
- Gracefully handles token removal errors
- Navigates back to the LoginScreen and clears the navigation stack
- Called after API deletion succeeds

### 4. ProfileScreen (`lib/screens/profile/profile_screen.dart`)
**Updated Button Handler:**
The "Account verwijderen" (Delete Account) button now:
1. Shows a confirmation dialog with warning message
2. On confirmation, attempts to delete the profile
3. Shows a loading indicator during deletion
4. Handles errors gracefully with error messages
5. Calls `AppStateProvider.deleteProfile()` for cleanup and navigation

**User Flow:**
```
1. User taps "Account verwijderen"
   ↓
2. Confirmation dialog appears with warning
   ↓
3. User confirms deletion
   ↓
4. Loading indicator shown
   ↓
5. API DELETE /profile/me/ is called (via AppStateProvider)
   ↓
6. Local data cleared, user logged out
   ↓
7. Redirected to LoginScreen
```

## Architecture Notes

### Design Pattern
The implementation follows the existing architecture patterns in the application:
- **Separation of Concerns**: API layer (ProfileApi), State Management (AppStateProvider), UI (ProfileScreen)
- **Dependency Injection**: ProfileApi is instantiated and provided via providers in main.dart
- **Error Handling**: Exceptions are thrown at the API layer and caught at the UI layer
- **State Management**: Provider package handles app state and notifies listeners

### API Client Integration
The implementation leverages the existing `ApiClient` class which:
- Automatically adds bearer token authentication headers
- Provides consistent error handling
- Logs all requests for debugging
- Supports all HTTP methods (GET, POST, PUT, DELETE, PATCH)

### Data Cleanup
When a profile is deleted:
1. **Local Storage**: Bearer token is removed from SharedPreferences
2. **In-Memory State**: All screen states and active reports are cleared
3. **Location Data**: Cached position and address data are cleared
4. **Navigation**: User is redirected to LoginScreen with stack cleared

## Error Handling

The implementation handles several error scenarios:

1. **Network Errors**: Propagated as exceptions from http package
2. **API Errors**: Non-success status codes throw descriptive exceptions
3. **Storage Errors**: Token removal failures are logged but don't block navigation
4. **UI Errors**: Try-catch blocks in ProfileScreen show error messages to users

## Testing Considerations

To test the profile deletion feature:

1. **Happy Path**:
   - Log in to the app
   - Navigate to Profile screen
   - Tap "Account verwijderen"
   - Confirm deletion
   - Verify user is logged out and redirected to LoginScreen

2. **Error Scenarios**:
   - Disconnect network and attempt deletion (should show error)
   - Invalid token and attempt deletion (should show error)
   - Verify error messages display correctly

3. **State Verification**:
   - Verify SharedPreferences are cleared after deletion
   - Verify navigation stack is cleared (no back button leads to old screens)
   - Verify app state is reset (no stale data on re-login)

## Related Code Files

- `lib/data_managers/api_client.dart` - HTTP client wrapper
- `lib/interfaces/data_apis/profile_api_interface.dart` - API contract
- `lib/data_managers/profile_api.dart` - API implementation
- `lib/providers/app_state_provider.dart` - App state management
- `lib/screens/profile/profile_screen.dart` - Profile UI screen
- `lib/main.dart` - App initialization and provider setup

## Notes

- The implementation follows the WildlifeNL API specification for DELETE /profile/me/
- Bearer token authentication is handled automatically by ApiClient
- The feature integrates seamlessly with existing logout functionality
- All user data is properly cleaned up to prevent data leaks
- Error messages are in Dutch to match the app's language
