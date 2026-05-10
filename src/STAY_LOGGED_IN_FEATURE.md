# Stay Logged In Feature

## Overview
Implemented persistent authentication that keeps users logged in across app restarts. Users will only need to log in again when they:
1. Explicitly log out using the logout button
2. Uninstall the app from their device

## Changes Made

### 1. `lib/utils/token_validator.dart`
**Before:** Forced logout on every mobile app restart by removing the token
**After:** Checks for token existence and keeps users logged in

Key changes:
- Removed platform-specific logic that cleared tokens on mobile
- Added `clearToken()` method for explicit logout
- Added comprehensive documentation

```dart
static Future<bool> hasValidToken() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('bearer_token');
  return token != null && token.isNotEmpty;
}
```

### 2. `lib/main.dart`
**Before:** Used FutureBuilder in home widget (redundant token check)
**After:** Uses pre-checked `initialScreen` directly

Key changes:
- Removed duplicate `getHomepageBasedOnLoginStatus()` function
- Simplified MyApp widget to use `initialScreen` parameter directly
- Single token validation on app startup

## How It Works

### Login Flow
1. User enters email → receives verification code
2. User enters code → backend validates and returns token
3. Token is stored in SharedPreferences via `AuthApi.authorize()`
4. User is navigated to OverzichtScreen

### App Restart Flow
1. App starts → `TokenValidator.hasValidToken()` checks for token
2. If token exists → Navigate to OverzichtScreen (stay logged in) ✅
3. If no token → Navigate to LoginScreen

### Logout Flow
1. User taps logout button (in OverzichtScreen or ProfileScreen)
2. `AppStateProvider.logout()` is called
3. Token is removed from SharedPreferences
4. App state is cleared
5. User is navigated to LoginScreen

### App Uninstall Flow
1. User uninstalls app from device
2. OS automatically clears all SharedPreferences (including token)
3. On reinstall, no token exists → User must log in again

## Testing Instructions

### Test 1: Stay Logged In (Expected: ✅ Pass)
1. Open app
2. Log in with valid credentials
3. Close app completely (swipe away from recent apps)
4. Reopen app
5. **Expected:** You should be logged in and see OverzichtScreen

### Test 2: Logout Works (Expected: ✅ Pass)
1. While logged in, navigate to Profile or Overzicht
2. Tap the logout button
3. **Expected:** You should be logged out and see LoginScreen
4. Close and reopen app
5. **Expected:** You should still see LoginScreen (token cleared)

### Test 3: Fresh Install (Expected: ✅ Pass)
1. Uninstall the app completely
2. Reinstall the app
3. Open app
4. **Expected:** You should see LoginScreen (no token)

### Test 4: Token Persistence (Expected: ✅ Pass)
1. Log in successfully
2. Force-stop the app from system settings
3. Reopen app
4. **Expected:** You should still be logged in

### Test 5: Background/Foreground (Expected: ✅ Pass)
1. Log in successfully
2. Press home button (app goes to background)
3. Wait a few minutes
4. Reopen app
5. **Expected:** You should still be logged in

## Security Considerations

1. **Token Storage:** Token is stored in SharedPreferences (encrypted by OS)
2. **Token Lifetime:** Backend should implement token expiration
3. **Token Revocation:** Backend should validate token on each API request
4. **Logout:** Always clears token from device

## Backend Requirements

The backend should:
1. Return a valid token on successful authentication
2. Validate token on each authenticated API request
3. Return 401 Unauthorized if token is invalid/expired
4. Handle token expiration (recommend 30-90 days)

## Files Modified

1. `lib/utils/token_validator.dart` - Core authentication validation logic
2. `lib/main.dart` - App initialization and routing logic

## Existing Files (No Changes Needed)

1. `lib/data_managers/auth_api.dart` - Already stores token correctly
2. `lib/providers/app_state_provider.dart` - Already has logout() method
3. `lib/screens/shared/overzicht_screen.dart` - Already has logout button
4. `lib/screens/profile/profile_screen.dart` - Already has logout button

## Migration Notes

Users upgrading from the previous version:
- Previous version: Forced logout on every app restart
- New version: Users stay logged in
- No data migration needed
- Users currently logged in will remain logged in after update

## Future Enhancements

Potential improvements:
1. Add biometric authentication (fingerprint/face ID)
2. Add "Remember me" checkbox on login screen
3. Implement automatic token refresh
4. Add session timeout warnings
5. Add multi-device session management
