# Profile Update Feature Implementation

## Overview
Complete implementation of the profile update feature using the WildlifeNL API endpoint `PUT /profile/me/`. Users can now edit their profile information on a dedicated edit page.

## API Endpoint
- **Method**: PUT
- **Endpoint**: `/profile/me/`
- **Authentication**: Bearer token (required)
- **Response**: 200 OK with updated Profile object

## Implemented Components

### 1. Profile Model (`lib/models/beta_models/profile_model.dart`)
**New Fields Added:**
- `dateOfBirth` (String?) - User's date of birth in YYYY-MM-DD format
- `description` (String?) - User's bio/description
- `location` (Map<String, dynamic>?) - User's location with latitude/longitude
- `locationTimestamp` (String?) - Last location update timestamp

**Updated Methods:**
- `toJson()` - Conditionally includes optional fields
- `fromJson()` - Parses all new fields from API response

### 2. ProfileApiInterface (`lib/interfaces/data_apis/profile_api_interface.dart`)
**New Abstract Method:**
```dart
Future<Profile> updateMyProfile(Profile updatedProfile);
```

### 3. ProfileApi (`lib/data_managers/profile_api.dart`)
**Implementation of updateMyProfile():**
- Makes PUT request to `/profile/me/` with authenticated bearer token
- Sends complete profile object with all required fields
- Handles 200 OK response
- Caches updated profile locally
- Returns updated Profile object
- Throws meaningful exceptions on failure

**Features:**
- Proper error handling with HTTP status codes
- Debug logging for troubleshooting
- Automatic bearer token authentication
- Local cache synchronization

### 4. EditProfileScreen (`lib/screens/profile/edit_profile_screen.dart`)
**New Screen for Profile Editing**

**Form Fields:**
- **Name** (required, minimum 2 characters)
- **Gender** (dropdown: female, male, other)
- **Date of Birth** (date picker - YYYY-MM-DD format)
- **Postcode** (optional text field)
- **Description** (optional text area, up to 4 lines)

**Features:**
- ✅ Pre-populated with current profile data
- ✅ Form validation (name length check)
- ✅ Date picker for date of birth selection
- ✅ Dropdown for gender selection
- ✅ Loading indicator during save
- ✅ Error handling with user-friendly messages
- ✅ Success notification after update
- ✅ Responsive design matching app theme
- ✅ Automatic return to ProfileScreen after save

**UI Components:**
- Back navigation button
- Input validation feedback
- Loading state management
- Error/Success SnackBar notifications
- Consistent styling with app colors

### 5. ProfileScreen Updates (`lib/screens/profile/profile_screen.dart`)
**Updated "Gegevens bijwerken" Button:**

**Flow:**
1. Fetch current profile from API
2. Navigate to EditProfileScreen with current data
3. User edits and saves
4. Receives updated Profile object
5. Updates UI with new userName
6. Shows success notification

**Error Handling:**
- Catches profile fetch errors
- Shows error messages to user
- Gracefully handles navigation issues

## User Flow

```
Profile Screen
    ↓
User taps "Gegevens bijwerken"
    ↓
Fetch Current Profile (GET /profile/me/)
    ↓
Navigate to EditProfileScreen
    ↓
User Edits Form Fields
    ↓
User taps "Opslaan"
    ↓
Validation Check (name ≥ 2 chars)
    ↓
API Call: PUT /profile/me/ with updated data
    ↓
Success → Cache profile locally
    ↓
Return to ProfileScreen with updated data
    ↓
Show success notification
    ↓
Update displayed username
```

## API Request/Response Format

### Request Body (PUT /profile/me/)
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "gender": "male",
  "postcode": "1234AB",
  "dateOfBirth": "1990-05-15",
  "description": "Nature enthusiast",
  "reportAppTerms": true,
  "recreationAppTerms": true
}
```

### Response (200 OK)
```json
{
  "ID": "3892eb50-4697-4c72-aadc-32b766bce3c0",
  "email": "john@example.com",
  "name": "John Doe",
  "gender": "male",
  "postcode": "1234AB",
  "dateOfBirth": "1990-05-15",
  "description": "Nature enthusiast",
  "reportAppTerms": true,
  "recreationAppTerms": true,
  "location": {
    "latitude": 51.7,
    "longitude": 5.27
  },
  "locationTimestamp": "2024-12-08T10:30:00Z"
}
```

## Form Validation

### Mandatory Fields
- **Name**: Minimum 2 characters

### Optional Fields
- Gender, Postcode, Date of Birth, Description

### Error Messages (Dutch)
- "Naam moet minstens 2 karakters lang zijn"
- "Fout bij bijwerken: [error details]"
- "Profiel succesvol bijgewerkt"

## UI/UX Features

### EditProfileScreen
- **Header**: "Profiel Bijwerken" with back button
- **Form Styling**: 
  - Light mint green input fields
  - Dark green focus border
  - Proper spacing and alignment
- **Date Picker**: Native Flutter date picker (range: 1900 - today)
- **Gender Dropdown**: Styled dropdown with capitalized options
- **Save Button**: 
  - Light mint green background
  - Green on hover/press
  - Loading spinner during API call
  - Disabled when loading
- **Feedback**:
  - Success: Green SnackBar for 2 seconds
  - Error: Red SnackBar for 3 seconds

### ProfileScreen Integration
- Button navigates with navigation transition
- Fetches fresh profile before edit
- Updates username display after successful edit
- Shows success message to user

## Testing Checklist

### Happy Path
- [ ] User taps "Gegevens bijwerken" button
- [ ] Current profile loads and displays in edit form
- [ ] User can edit each field
- [ ] Date picker works correctly
- [ ] Gender dropdown works
- [ ] Save button triggers API call
- [ ] Loading indicator shows during save
- [ ] API returns 200 with updated profile
- [ ] Success message appears
- [ ] Screen returns to ProfileScreen
- [ ] Username updated in profile view

### Error Scenarios
- [ ] Invalid name (< 2 chars) - validation shows
- [ ] Network error during fetch - error message shown
- [ ] Network error during save - error message shown, data preserved
- [ ] API returns validation error - error message shown
- [ ] User navigates back without saving - no API call

### Edge Cases
- [ ] Empty optional fields handled correctly
- [ ] Special characters in name/description
- [ ] Maximum field lengths
- [ ] Date formatting consistency
- [ ] Responsive design on small screens

## Related Files Modified

1. `lib/models/beta_models/profile_model.dart` - Updated model with new fields
2. `lib/interfaces/data_apis/profile_api_interface.dart` - Added interface method
3. `lib/data_managers/profile_api.dart` - Implemented API call
4. `lib/screens/profile/edit_profile_screen.dart` - Created new edit screen
5. `lib/screens/profile/profile_screen.dart` - Updated navigation to edit screen

## Architecture Notes

### Design Pattern
- **Separation of Concerns**: Data layer (ProfileApi), State Management (Provider), UI (Screens)
- **Single Responsibility**: Each component handles one concern
- **Error Handling**: Try-catch at UI level, exceptions thrown at API level
- **State Management**: Provider pattern for dependency injection

### Data Flow
1. User interaction triggers navigation
2. Current profile fetched via ProfileApi
3. EditProfileScreen displays form with prefilled data
4. User edits and submits
5. ProfileApi makes PUT request
6. Response cached locally
7. UI updated with returned data

### Error Handling Strategy
- **API Layer**: Throws exceptions with HTTP status and body
- **UI Layer**: Catches exceptions and shows user-friendly messages
- **Navigation**: Checks `mounted` before state updates post-navigation
- **Recovery**: User can retry without losing form data

## Future Enhancements

Potential improvements for future iterations:
- [ ] Image/avatar upload support
- [ ] Location verification
- [ ] Bio markdown formatting
- [ ] Profile picture from location/camera
- [ ] Duplicate email detection
- [ ] Phone number field
- [ ] Language preferences
- [ ] Privacy settings UI
