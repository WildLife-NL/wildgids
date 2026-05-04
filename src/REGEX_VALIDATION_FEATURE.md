# Regex Validation and Slider Feature for Questionnaires

## Overview
This feature adds input validation for free-format text questions using regex patterns, and automatically displays a slider interface for numeric range patterns like `[1-5]`.

## Implementation

### 1. Regex Validation
When a question's `openResponseFormat` field contains a regex pattern:
- Input is validated in real-time as the user types
- Validation errors are displayed below the text field with helpful hints
- The "Next" button is disabled when validation fails
- Empty input is always allowed (validation only applies when text is entered)

### 2. Numeric Range Slider
When `openResponseFormat` matches the pattern `[min-max]`:
- A slider is automatically displayed instead of a text field
- The slider ranges from min to max with integer steps
- The current value is prominently displayed
- Min and max values are shown as labels
- Reversed ranges (e.g., `[5-1]`) are automatically corrected

### 3. User Experience Features
- **Smart validation**: Helpful error messages based on pattern type
  - Numeric patterns: "alleen cijfers"
  - Letter patterns: "alleen letters"
  - Email patterns: "e-mailadres"
- **Button control**: Next button is disabled when:
  - Text field is empty (requires input)
  - Validation fails (invalid format)
- **Visual feedback**: Red border and error text when validation fails

## Code Changes

### Modified Files

**`lib/widgets/questionnaire/questionnaire_open_response.dart`**
- Added `_canProceed` flag to track validation state
- Enhanced `_checkIfNumericRange()` to properly detect `[min-max]` patterns
- Improved `_validateText()` with better error messages and hints
- Added validation on initialization for existing responses
- Implemented next button control based on validation state
- Added `_buildSlider()` method for numeric range UI
- Added `_buildTextField()` method with validation styling

**`lib/models/api_models/question.dart`**
- Already has `openResponseFormat` field (no changes needed)

## Usage Examples

### Example 1: Numeric-Only Input
```json
{
  "openResponseFormat": "^\\d+$",
  "text": "Hoeveel dieren heb je gezien?"
}
```
Result: Text field that only accepts digits, shows "alleen cijfers" hint when validation fails

### Example 2: Email Validation
```json
{
  "openResponseFormat": "^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}$",
  "text": "Wat is je e-mailadres?"
}
```
Result: Text field that validates email format, shows "e-mailadres" hint

### Example 3: Slider for Rating 1-5
```json
{
  "openResponseFormat": "[1-5]",
  "text": "Hoe tevreden ben je? (1 = zeer ontevreden, 5 = zeer tevreden)"
}
```
Result: Interactive slider from 1 to 5 with large value display

### Example 4: Slider for Percentage 0-100
```json
{
  "openResponseFormat": "[0-100]",
  "text": "Wat is het geschatte percentage vegetatie?"
}
```
Result: Interactive slider from 0 to 100

### Example 5: Phone Number
```json
{
  "openResponseFormat": "^\\+31\\d{9}$",
  "text": "Wat is je telefoonnummer?"
}
```
Result: Text field validating Dutch phone number format (+31xxxxxxxxx)

## Supported Regex Patterns

### Numeric Range (Slider)
- `[1-5]` - Slider from 1 to 5
- `[0-10]` - Slider from 0 to 10
- `[1-100]` - Slider from 1 to 100
- `[5-1]` - Automatically corrected to [1-5]

### Text Validation
- `^\\d+$` - Only digits
- `^[a-zA-Z]+$` - Only letters
- `^[a-zA-Z\\s]+$` - Only letters and spaces
- `^\\d{4}$` - Exactly 4 digits
- `^[a-zA-Z0-9]+$` - Alphanumeric only

### Complex Patterns
- `^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}$` - Email address
- `^\\+31\\d{9}$` - Dutch phone number
- `^\\d{4}[A-Z]{2}$` - Dutch postal code (1234AB)
- `^https?://.*$` - URL starting with http:// or https://

## Error Handling

### Invalid Regex
If the regex pattern is malformed:
- Error is logged to console
- Validation is skipped (accepts any input)
- User is not blocked from proceeding

### Edge Cases
- Empty input: Always allowed (validation only when text entered)
- Whitespace: Trimmed for numeric range detection
- Case sensitivity: Depends on the regex pattern flags

## Testing

### Manual Testing Steps

1. **Test Numeric Slider**:
   - Create question with `openResponseFormat: "[1-5]"`
   - Verify slider appears with range 1-5
   - Move slider and verify value updates
   - Submit and verify correct value saved

2. **Test Regex Validation**:
   - Create question with `openResponseFormat: "^\\d+$"`
   - Enter "123" - should be valid
   - Enter "abc" - should show error
   - Verify next button disabled when error shown

3. **Test Empty Input**:
   - Enter invalid text (error shown)
   - Clear all text
   - Verify error disappears and button enabled

4. **Test Error Messages**:
   - Try patterns with `\\d` - verify "alleen cijfers" hint
   - Try patterns with `[a-zA-Z]` - verify "alleen letters" hint
   - Try patterns with `@` - verify "e-mailadres" hint

### Backend Integration

The backend should:
1. Set `openResponseFormat` field in Question JSON
2. Use standard regex patterns (JavaScript/Dart compatible)
3. Escape special characters properly in JSON

Example backend JSON:
```json
{
  "questions": [
    {
      "ID": "q1",
      "text": "Rate your satisfaction",
      "allowOpenResponse": true,
      "openResponseFormat": "[1-5]",
      "...": "..."
    },
    {
      "ID": "q2",
      "text": "Enter your email",
      "allowOpenResponse": true,
      "openResponseFormat": "^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}$",
      "...": "..."
    }
  ]
}
```

## Benefits

1. **Data Quality**: Ensures responses match expected format
2. **User Experience**: Clear feedback and intuitive slider for numeric ranges
3. **Flexibility**: Supports any regex pattern the backend defines
4. **Error Prevention**: Prevents form submission with invalid data
5. **Accessibility**: Slider provides better UX for numeric input than keyboard

## Future Enhancements

Potential improvements:
- Add support for custom error messages from backend
- Support for multi-line regex patterns
- Date/time pickers for date patterns
- Color picker for hex color patterns
- File upload validation for file extension patterns
