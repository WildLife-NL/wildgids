# Issue #145 - Multiple Choice Questions with Per-Answer Free Text

## Status: ✅ IMPLEMENTATION COMPLETE, ⏳ AWAITING BACKEND DATA

## What Was Implemented

### 1. Enhanced Logging for Debugging
- **File**: `lib/data_managers/interaction_api.dart`
- **Change**: Added detailed logging to show exactly what the backend sends
  - Displays questionnaire structure
  - Lists all questions and their answer choices
  - Clearly marks when answers are missing: `❌ NO ANSWERS PROVIDED by backend!`

- **File**: `lib/managers/other/questionnaire_manager.dart`
- **Change**: Added warning when questions claim to support multiple responses but have no answers
  - Helps identify backend data issues immediately
  - Shows detailed answer breakdown with ID and text

### 2. Per-Answer Text Field Support
- **File**: `lib/widgets/questionnaire/questionnaire_multiple_choice.dart`
- **Changes Made**:
  - ✅ Added `Map<String, TextEditingController> _textControllers` - manages text input per answer
  - ✅ Added `Map<String, String> _freeTextByAnswer` - caches per-answer text
  - ✅ Added `_allowFreeText` getter - determines if text fields should be shown
  - ✅ Added `_initTextControllers()` - creates controllers for all answer IDs
  - ✅ Added `_hydrateExistingText()` - restores prior text from stored responses
  - ✅ Added `_onSelectAnswer()` - handles selection state and text field visibility
  - ✅ Added `_saveResponse()` - stores both answer selection AND per-answer text
  - ✅ Added `dispose()` - properly cleans up TextEditingControllers
  - ✅ Modified `build()` - renders TextField under each selected answer when enabled

### 3. Data Storage Format
Response data is stored as JSON in the `text` field:
```json
{
  "answerId1": "user feedback for answer 1",
  "answerId2": "user feedback for answer 2",
  "answerId3": "user feedback for answer 3"
}
```

Backward compatible: plain-text responses still supported if JSON parsing fails.

### 4. Unit Tests Added
- **File**: `test/business/managers/questionnaire_manager_test.dart`
- **New Tests**:
  - Test for rendering MultipleChoice when answers ARE provided
  - Test for rendering OpenResponse when answers are NOT provided
  - Test for warning message when allowMultipleResponse=true but no answers exist

## What's NOT Working Yet

### Root Cause: Backend Not Sending Answer Choices

The test questionnaire "test multiple options" is missing the `answers` array in the question data.

**Evidence from debug logs**:
```
Question 1: test questions
  ID: 611ff371-c684-44da-b12b-8261d8be5e9b
  allowMultipleResponse: true
  allowOpenResponse: true
  Has Answers: false
  ❌ NO ANSWERS PROVIDED by backend!
```

### Current Behavior
Since the backend doesn't send answer choices, the questionnaire routing logic correctly falls back to:
```
hasAnswers = false
needsOpenResponse = true
✅ Using QuestionnaireOpenResponse widget
```

This renders a simple text field instead of checkboxes with per-answer text fields.

## What You Need to Do (Backend)

To test the per-answer text field implementation, you need to:

1. Go to your backend questionnaire admin interface
2. Find the "test multiple options" questionnaire
3. Edit the question(s) and **add answer choices** (e.g., "Option 1", "Option 2", "Option 3")
4. Ensure the API response includes these answers:
   ```json
   {
     "questions": [
       {
         "ID": "...",
         "text": "...",
         "allowMultipleResponse": true,
         "allowOpenResponse": true,
         "answers": [
           {"ID": "a1", "text": "Option 1", "index": 0},
           {"ID": "a2", "text": "Option 2", "index": 1},
           {"ID": "a3", "text": "Option 3", "index": 2}
         ]
       }
     ]
   }
   ```

## Testing Steps (Once Backend is Fixed)

1. Run the app: `flutter run`
2. Create a report that triggers the "test multiple options" questionnaire
3. You should see:
   - ✅ Checkboxes for each answer choice
   - ✅ Text field appears when you select an answer
   - ✅ Each selected answer can have its own text feedback
   - ✅ Responses persist when navigating back/forward

4. Monitor the console for:
   ```
   ✅ Has ${answers.length} answers:
        [A1] Option 1 (ID: a1)
        [A2] Option 2 (ID: a2)
        [A3] Option 3 (ID: a3)
   ```

## Code Files Modified

1. `lib/widgets/questionnaire/questionnaire_multiple_choice.dart` - Per-answer text field implementation
2. `lib/data_managers/interaction_api.dart` - Enhanced logging for questionnaire data
3. `lib/managers/other/questionnaire_manager.dart` - Warning messages for missing answers
4. `test/business/managers/questionnaire_manager_test.dart` - Unit tests for routing logic
5. `test/widgets/questionnaire_multiple_choice_with_text_test.dart` - Widget tests (created)

## Summary

The frontend implementation is **complete and ready to use**. The feature is currently blocked by backend data not being sent. Once the backend questionnaire includes answer choices, everything will work as expected.

The enhanced logging will guide you to any remaining issues.
