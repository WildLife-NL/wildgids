# Fixing Map Display Issue in Android Release Builds

**Date:** 03/12/2025  
**Project:** Wildlife NL - Wild Gids App  

---

## What

### The Problem
The map screen showed a **grey screen** when installed as a release APK, but worked perfectly in debug mode.

**Symptoms:**
- ✅ Map works in debug build (`flutter run`)
- ❌ Map shows grey screen in release APK
- Filter and center buttons still visible
- API and location services working correctly

### The Solution
Fixed incorrect widget structure in FlutterMap + updated ProGuard rules.

---

## Why

### What is `build.gradle.kts`?
Android's build configuration file that controls how your app is compiled.

**Location:** `android/app/build.gradle.kts` (screenshot this file, lines 35-50)

**What it does:**
- `isMinifyEnabled = true` → Enables code shrinking with ProGuard/R8
- `proguardFiles` → Tells Android which ProGuard rules to use

### What is `proguard-rules.pro`?
Rules file that tells ProGuard what code to keep or remove.

**Location:** `android/app/proguard-rules.pro` (screenshot this file)

**What ProGuard does:**
- Removes unused code to reduce APK size
- Renames classes for security (obfuscation)
- Can accidentally remove code that's needed at runtime

### Why debug worked but release didn't
- Debug: No code optimization, Flutter tolerates bad code structure
- Release: ProGuard optimizations break invalid widget structure

---

## How

### 1. The Main Fix - Widget Structure

**File:** `lib/screens/location/kaart_overview_screen.dart`  
**Lines:** ~895-920 (screenshot these lines)

**Problem:** The rotate button was INSIDE FlutterMap's children list. FlutterMap only accepts map layers, not UI widgets.

**Solution:** Moved the rotate button OUT of FlutterMap into the parent Stack.

```dart
// BEFORE (Wrong):
fm.FlutterMap(
  children: [
    Positioned(...),  // ❌ Button inside map
    fm.TileLayer(...),
  ],
)

// AFTER (Fixed):
Stack(
  children: [
    fm.FlutterMap(
      children: [
        fm.TileLayer(...),  // ✅ Only map layers
      ],
    ),
    Positioned(...),  // ✅ Button outside map
  ],
)
```

### 2. ProGuard Rules Fix

**File:** `android/app/proguard-rules.pro` (screenshot this file)

**BEFORE (What was there originally):**
```proguard
-keep class com.example.wildrapport.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }

-dontwarn io.flutter.embedding.**
-dontwarn android.**
```

**AFTER (What we changed it to):**
```proguard
-keep class com.example.wildrapport.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }

-dontwarn io.flutter.embedding.**
-dontwarn android.**

# NEW: Disable obfuscation and optimization
-dontobfuscate
-dontoptimize

# NEW: Keep everything - prevents code stripping
-keepclassmembers class * { *; }
-keep class * { *; }

# NEW: Preserve debugging info
-keepattributes SourceFile,LineNumberTable
-keepattributes *Annotation*
```

**What changed:**
- Added `-dontobfuscate` → Don't rename classes
- Added `-dontoptimize` → Don't optimize code
- Added `-keep class * { *; }` → Keep ALL classes
- Added `-keepclassmembers class * { *; }` → Keep ALL methods/fields
- Added `-keepattributes` → Keep metadata for debugging

### 3. Build Configuration

**File:** `android/app/build.gradle.kts` (screenshot lines 35-50)

**BEFORE (What was there originally):**
```kotlin
buildTypes {
  release {
    signingConfig = signingConfigs.getByName("debug")
    isMinifyEnabled = true
    proguardFiles(
      getDefaultProguardFile("proguard-android-optimize.txt"),
      "proguard-rules.pro"
    )
  }
}
```

**AFTER (What we changed it to):**
```kotlin
buildTypes {
  release {
    signingConfig = signingConfigs.getByName("debug")
    isMinifyEnabled = true
    isShrinkResources = false  // NEW: Added this line
    proguardFiles(
      getDefaultProguardFile("proguard-android.txt"),  // CHANGED: removed -optimize
      "proguard-rules.pro"
    )
  }
}
```

**What changed:**
- Added `isShrinkResources = false` → Don't remove resources
- Changed `proguard-android-optimize.txt` → `proguard-android.txt` (less aggressive optimization)

---

## Files to Screenshot

1. **`android/app/build.gradle.kts`** - Lines 35-50
2. **`android/app/proguard-rules.pro`** - Entire file
3. **`lib/screens/location/kaart_overview_screen.dart`** - Lines 895-920 (the Stack/FlutterMap structure)

---

## Result

- ✅ Map now works in release APK
- APK size increased from 104MB → 140MB (acceptable trade-off)
