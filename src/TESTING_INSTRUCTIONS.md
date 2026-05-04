# Testing Instructions for Questionnaire Answer Submission

## Changes Made

### 1. Fixed Response Storage Bug (response_manager.dart)
**Problem:** Single multiple-choice answers were not being stored locally before submission.

**Fix:** Changed logic at lines 115-137 from nested if statement to if-else statement:
```dart
// OLD (BUGGY):
if (answerID != null) {
  if (contains(',')) {
    // handle multiple answers
  }
}
// Single answers were never stored!

// NEW (FIXED):
if (answerID != null && contains(',')) {
  // handle multiple comma-separated answers
} else if (answerID != null) {
  // handle single answer - THIS NOW WORKS!
}
```

### 2. Enabled Different Report Types (location_screen.dart & rapporteren.dart)
**Problem:** App always used InteractionType.waarneming, so same questionnaire always loaded.

**Fix:** 
- Added mapping from ReportType → InteractionType in location_screen.dart
- Enabled "Verkeersongeval" button in rapporteren.dart (was disabled)
- Now the app uses the correct interaction type based on selected report

**Mapping:**
- ReportType.waarneming → InteractionType.waarneming
- ReportType.gewasschade → InteractionType.gewasschade  
- ReportType.verkeersongeval → InteractionType.verkeersongeval

## How to Test

### Step 1: Test Different Report Types
1. Start the app
2. Navigate to "Rapporteren" screen
3. You should see 4 buttons:
   - **Gewasschade** (Crop Damage)
   - **Diergezondheid** (Animal Health)
   - **Waarnemingen** (Sightings)
   - **Verkeersongeval** (Traffic Accident) ← NOW ENABLED!

### Step 2: Test Waarneming (Sighting) Flow
1. Tap "Waarnemingen"
2. Select a category (e.g., "Mammal")
3. Select an animal (e.g., "Wild boar")
4. Fill in location and datetime
5. Submit
6. You should get the **Waarneming questionnaire**
7. Answer ALL THREE questions:
   - Question 1 (Single choice): Select one answer
   - Question 2 (Multiple choice): Select multiple answers
   - Question 3 (Open text): Type some text
8. Submit the questionnaire
9. **Expected:** All 3 answers POST to backend successfully

### Step 3: Test Gewasschade (Crop Damage) Flow
1. Go back to "Rapporteren"
2. Tap "Gewasschade"
3. Fill in crop damage details
4. Fill in location and datetime
5. Submit
6. You should get the **Gewasschade questionnaire** (different from Waarneming!)
7. Answer all questions
8. Submit
9. **Expected:** All answers POST successfully

### Step 4: Test Verkeersongeval (Traffic Accident) Flow
1. Go back to "Rapporteren"
2. Tap "Verkeersongeval"
3. Select a category and animal
4. Fill in location and datetime
5. Submit
6. You should get the **Verkeersongeval questionnaire** (different from others!)
7. Answer all questions
8. Submit
9. **Expected:** All answers POST successfully

## What to Look For

### In the Logs (Debug Console)
You should see:
```
[LocationScreen] Using report type: ReportType.waarneming -> interaction type: InteractionType.waarneming
[ResponseApi] Sending POST request to: response/
[ResponseApi] Request payload: {answerID: xxx, interactionID: yyy, questionID: zzz}
[ResponseApi] Response status code: 200
[ResponseApi] Response body contains ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

Repeat for each answer (3 times per questionnaire).

### In the Database
Check the backend database at: https://test-api-wildlifenl.uu.nl

Each questionnaire submission should create:
- 1 interaction record (with correct type: waarneming/gewasschade/verkeersongeval)
- 3 response records (one for each answer type)

Example response IDs you should find:
- Single choice answer: UUID like 4262a452-44ea-40bd-92fe-ab0b1dbed160
- Multiple choice answer: UUID (new)
- Open text answer: UUID (new)

All 3 should have the same `interactionID` linking them together.

## Verification Checklist

- [ ] Waarneming questionnaire loads for "Waarnemingen" report
- [ ] Gewasschade questionnaire loads for "Gewasschade" report  
- [ ] Verkeersongeval questionnaire loads for "Verkeersongeval" report
- [ ] Single choice answers submit successfully (all 3 report types)
- [ ] Multiple choice answers submit successfully (all 3 report types)
- [ ] Open text answers submit successfully (all 3 report types)
- [ ] All responses have HTTP 200 status
- [ ] All responses return database IDs in response body
- [ ] Database contains all submitted responses

## Bug Fix Confirmation

**Before fix:** Only open text answers reached database (1 out of 3)
**After fix:** All answer types reach database (3 out of 3) ✓

The bug was in `response_manager.dart` where single multiple-choice answers were never stored in SharedPreferences, so they never got submitted to the API.

## Backend Configuration Note

Make sure each interaction type has a questionnaire assigned in the backend:
- waarneming → waarnemingTestVragenlijst ✓ (confirmed working)
- gewasschade → (verify questionnaire exists in backend)
- verkeersongeval → (verify questionnaire exists in backend)

If a questionnaire is missing for a type, the POST to /interaction/ will return a questionnaire with no questions.
