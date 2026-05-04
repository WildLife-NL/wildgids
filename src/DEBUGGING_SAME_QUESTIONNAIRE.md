# Debugging: Getting Same Questionnaire for All Report Types

## Issue
You're seeing responses in the database, but still getting the same questionnaire regardless of which report type you select (Waarneming, Gewasschade, or Verkeersongeval).

## Root Cause Analysis

The questionnaire is loaded from the **interaction POST response**, NOT from the hard-coded ID in `questionnaire_manager.dart`.

The flow is:
1. User selects report type → `appStateProvider.initializeReport(reportType)` is called
2. User fills in details and location → `submitReport()` is called
3. `submitReport()` reads `currentReportType` from AppStateProvider
4. Maps ReportType → InteractionType
5. POSTs to `/interaction/` with the correct InteractionType
6. Backend returns interaction + **embedded questionnaire**
7. App displays the returned questionnaire

## Possible Causes

### 1. App Needs Hot Restart (Most Likely)
**Problem:** Hot reload doesn't reinitialize providers or change method signatures.

**Solution:** 
```bash
# Stop the app completely
# Then restart:
flutter run
```

Or press:
- `R` for hot restart (capital R)
- NOT `r` for hot reload (lowercase r)

### 2. Backend Configuration Issue
**Problem:** All interaction types might be configured to use the same questionnaire in the backend.

**Check:** Look at the interaction POST response in the logs:
```
[LocationScreen] Using report type: ReportType.gewasschade -> interaction type: InteractionType.gewasschade
```

Then check the questionnaire name/ID in the response:
```
[LocationScreen] Received valid questionnaire: [NAME HERE]
```

If the name is the same for all types → backend configuration issue.

### 3. AppStateProvider Not Being Read
**Problem:** The report type might not be persisting between screens.

**Debug Steps:**
1. Select a report type (e.g., Gewasschade)
2. Look for this log:
   ```
   [AppStateProvider] 🔷 Initializing report with type: ReportType.gewasschade
   ```
3. Continue to location screen
4. Submit and look for:
   ```
   [LocationScreen] Using report type: ReportType.gewasschade -> interaction type: InteractionType.gewasschade
   ```

If you see `ReportType.waarneming` in step 4 when you selected Gewasschade → provider issue.

## Step-by-Step Debugging

### Test 1: Waarneming (Baseline)
1. **Hot restart** the app (press `R` in terminal, or stop and `flutter run`)
2. Tap "Waarnemingen"
3. Expected log: `🔷 Initializing report with type: ReportType.waarneming`
4. Fill in animal, location, etc.
5. Submit
6. Expected logs:
   ```
   [LocationScreen] Using report type: ReportType.waarneming -> interaction type: InteractionType.waarneming
   [LocationScreen] Received valid questionnaire: waarnemingTestVragenlijst
   ```
7. Note the questionnaire name/ID

### Test 2: Gewasschade
1. Go back to Rapporteren
2. Tap "Gewasschade"
3. Expected log: `🔷 Initializing report with type: ReportType.gewasschade`
4. Fill in crop damage details
5. Submit
6. Expected logs:
   ```
   [LocationScreen] Using report type: ReportType.gewasschade -> interaction type: InteractionType.gewasschade
   [LocationScreen] Received valid questionnaire: [DIFFERENT NAME]
   ```
7. **Compare**: Is the questionnaire name different from Test 1?

### Test 3: Verkeersongeval
1. Go back to Rapporteren
2. Tap "Verkeersongeval"
3. Expected log: `🔷 Initializing report with type: ReportType.verkeersongeval`
4. Fill in details
5. Submit
6. Expected logs:
   ```
   [LocationScreen] Using report type: ReportType.verkeersongeval -> interaction type: InteractionType.verkeersongeval
   [LocationScreen] Received valid questionnaire: [DIFFERENT NAME]
   ```
7. **Compare**: Is this a third unique questionnaire?

## What the Logs Should Show

### ✅ Good Scenario (Different Questionnaires)
```
Test 1: waarnemingTestVragenlijst (ID: 5c5cd71a-ed88-4e18-8cd4-725a6c6fe4b1)
Test 2: gewasschadeVragenlijst (ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)
Test 3: verkeersongevalVragenlijst (ID: yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy)
```

### ❌ Bad Scenario (Same Questionnaire)
```
Test 1: waarnemingTestVragenlijst (ID: 5c5cd71a-ed88-4e18-8cd4-725a6c6fe4b1)
Test 2: waarnemingTestVragenlijst (ID: 5c5cd71a-ed88-4e18-8cd4-725a6c6fe4b1) <- WRONG!
Test 3: waarnemingTestVragenlijst (ID: 5c5cd71a-ed88-4e18-8cd4-725a6c6fe4b1) <- WRONG!
```

If you see the bad scenario, the issue is in the **backend configuration**, NOT the Flutter app.

## Backend Configuration Check

Contact your backend admin and verify:

1. **Interaction types exist:**
   - `waarneming`
   - `gewasschade`
   - `verkeersongeval`

2. **Each type has a questionnaire assigned:**
   ```sql
   SELECT interaction_type, questionnaire_id, questionnaire_name 
   FROM interaction_type_questionnaire_mapping;
   ```

3. **Questionnaires are different:**
   - Waarneming → 5c5cd71a-ed88-4e18-8cd4-725a6c6fe4b1 (confirmed)
   - Gewasschade → ??? (needs to be different)
   - Verkeersongeval → ??? (needs to be different)

## Quick Fix If Backend Not Configured

If the backend doesn't have different questionnaires for each type yet:

**Option A:** Test with mock data (create 3 different questionnaires in backend)

**Option B:** Modify the app temporarily to show which interaction type was used:
```dart
// In questionnaire_screen.dart
debugPrint('Questionnaire ID: ${questionnaire.id}');
debugPrint('Questionnaire Name: ${questionnaire.name}');
```

This will confirm the app is sending the correct interaction type, even if backend returns the same questionnaire.

## Summary Checklist

- [ ] Hot restart app (press `R`, not `r`)
- [ ] Test Waarneming → Check logs for `ReportType.waarneming` → Note questionnaire name
- [ ] Test Gewasschade → Check logs for `ReportType.gewasschade` → Note questionnaire name
- [ ] Test Verkeersongeval → Check logs for `ReportType.verkeersongeval` → Note questionnaire name
- [ ] Compare questionnaire names/IDs
- [ ] If same → Backend needs configuration
- [ ] If different → App working correctly! ✅

## Expected Result

After hot restart, you should see:
- ✅ Three different report types in logs
- ✅ Three different interaction types sent to backend
- ✅ Three different questionnaires returned (if backend configured)
- ✅ All answers still submitting successfully

The changes ARE working - you just need to restart to see them!
