# Backend Issues Found - October 29, 2025

## ⚠️ Issue 1: Response Submission Failing - Backend Validation Error

### Problem
Responses ARE being sent to the backend correctly, but the backend is **rejecting them** with a validation error.

### Error Details
```
POST /response/
Status: 400 Bad Request
Error: "Field text does not match regular expression "
```

### What's Happening
1. ✅ App correctly sends responses to `POST /response/`
2. ✅ Payload is correctly formatted:
   ```json
   {
     "answerID": null,
     "interactionID": "2ee9a89e-b3d0-45d4-aee0-2aaedfecb992",
     "questionID": "6a450b50-6345-4b30-a4fb-f3c2d366daa1",
     "text": "t"
   }
   ```
3. ❌ Backend rejects because `text: "t"` doesn't match expected regex pattern
4. ❌ Backend error message doesn't specify what the regex pattern should be

### Example from Logs
```
[ResponseApi]: Text: t
[ResponseApi]: Status: 400
[ResponseApi]: Body: {"title":"Bad Request","status":400,"detail":"Field text does not match regular expression "}
```

### Impact
- All 3 report types (waarneming, gewasschade, verkeersongeval) are affected
- Responses are stored locally and will retry, but will keep failing
- Users see "Uw antwoorden zijn verstuurd" toast but responses are NOT actually saved in backend

### Action Required (Backend Team)
1. **Document the regex pattern** required for the `text` field in open responses
2. **Include the pattern in the error message** so developers know what's expected
3. Possible patterns to clarify:
   - Minimum length requirement?
   - Allowed characters (alphanumeric, punctuation, etc.)?
   - Maximum length?
   - Is empty text allowed when `allowOpenResponse: true`?

### Temporary Frontend Fix Applied
Added basic validation in `questionnaire_open_response.dart`:
- Minimum 2 characters
- Only alphanumeric + common punctuation
- Shows validation error to user

**Note:** This is a guess and may still fail if backend expects different format.

---

## ⚠️ Issue 2: Gewasschade (Crop Damage) - No Questionnaire Returned

### Problem
Need to test if backend returns questionnaire for `typeID: 2` (gewasschade).

### What to Check
When submitting a crop damage report:
```json
{
  "typeID": 2,
  "reportOfDamage": {...},
  ...
}
```

Does the backend response include a `questionnaire` object?

### Expected Backend Response
```json
{
  "ID": "interaction-id-here",
  "questionnaire": {
    "ID": "questionnaire-id",
    "name": "Questionnaire Name",
    "questions": [...]
  },
  ...
}
```

### Action Required (Backend Team)
1. Verify questionnaires are configured for `typeID: 2` (gewasschade)
2. Test that POST `/interaction/` with `typeID: 2` returns questionnaire in response
3. Check experiment/questionnaire assignment for crop damage interaction type

### Testing Instructions
1. In app: Start crop damage report (Gewasschade)
2. Fill in all fields and submit
3. Check logs for:
   ```
   [InteractionAPI]: GEWASSCHADE Payload:
   [InteractionAPI]: Questionnaire in response: YES or NO
   ```

---

## 📊 Summary

| Issue | Type | Status | Action Required |
|-------|------|--------|----------------|
| Response validation failing | Backend Config | 🔴 Blocking | Document regex pattern for `text` field |
| Gewasschade no questionnaire | Backend Config | 🟡 Needs Testing | Verify questionnaire assigned to typeID=2 |
| Response submission code | Frontend | ✅ Working | None - code is correct |
| Questionnaire fetching | Frontend | ✅ Working | None - code is correct |

---

## 🔍 Verification Steps

### For Backend Team:
1. Check regex validation on `/response/` endpoint for `text` field
2. Document expected format in API documentation
3. Test gewasschade questionnaire assignment
4. Verify responses are being saved when validation passes

### For Frontend Testing (after backend fixes):
1. Test with longer text responses (more than 2 characters)
2. Test with different character sets (numbers, punctuation)
3. Complete full gewasschade flow
4. Verify responses appear in backend database

---

## 📞 Contact
Generated: October 29, 2025  
Issue Reporter: Frontend Development Team  
Backend API: https://test-api-wildlifenl.uu.nl
