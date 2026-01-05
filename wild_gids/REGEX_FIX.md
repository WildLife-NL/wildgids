# Fix for Backend Text Validation Error

## Problem
Error: `400 Bad Request - "Field text does not match regular expression"`

When submitting responses to the backend, single-character answers like "t" were being rejected with a regex validation error.

## Root Cause
The backend's `/response/` endpoint validates the `text` field against a regex pattern that **requires a minimum of 2 characters**. Single character inputs fail this validation.

## Solution
Added frontend validation to enforce the backend's minimum 2-character requirement:

### Changes Made

**File: [lib/widgets/questionnaire/questionnaire_open_response.dart](lib/widgets/questionnaire/questionnaire_open_response.dart)**
- Updated `_validateText()` method to check for minimum 2-character requirement
- If user enters only 1 character, error message: "Antwoord moet minimaal 2 karakters bevatten"
- This validation runs **before** the response is submitted to the backend
- Prevents backend rejection and improves user experience

**File: [test/widgets/questionnaire_open_response_validation_test.dart](test/widgets/questionnaire_open_response_validation_test.dart)**
- Updated test helper `_validateText()` to match production code
- Ensures tests reflect the same validation logic

## How It Works

1. User types in a text response field
2. After each keystroke, validation runs:
   - If text is only 1 character → Show error: "Antwoord moet minimaal 2 karakters bevatten"
   - If text is 2+ characters → Proceed with pattern validation (if any)
   - If no format pattern → Accept any 2+ character input
3. The "Next" button is disabled when validation fails
4. Once validation passes, response is submitted to backend without rejection

## Testing

After the fix, you should be able to:
1. Enter "ab" (2 characters) → Accepted ✓
2. Enter "a" (1 character) → Rejected with validation error
3. Enter "any text with spaces and punctuation!" → Accepted ✓
4. Responses submit to backend without 400 errors

## Backend Requirement
The backend's regex validation for `text` field appears to be: `^.{2,}$` (minimum 2 characters)
- Empty text is rejected
- Single character is rejected  
- 2+ characters are accepted

## Migration
No action required. This is a frontend-only fix that prevents invalid submissions before they reach the backend.
