-keep class com.example.wildrapport.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }

-dontwarn io.flutter.embedding.**
-dontwarn android.**

# Disable all obfuscation and optimization - just minify
-dontobfuscate
-dontoptimize

# Keep everything - nuclear option for debugging
-keepclassmembers class * { *; }
-keep class * { *; }

# Preserve line numbers for debugging
-keepattributes SourceFile,LineNumberTable
-keepattributes *Annotation*