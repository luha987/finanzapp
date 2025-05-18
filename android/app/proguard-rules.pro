# Keep Flutter classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Keep Firebase classes
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Keep Gson models (jika pakai JSON parsing)
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

# Keep Kotlin coroutines (jika pakai)
-keepclassmembers class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**

# Keep Dart plugin registrant
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# General AndroidX
-dontwarn androidx.**
-keep class androidx.** { *; }

# Avoid removing classes with annotations (like @Keep)
-keep @androidx.annotation.Keep class * {*;}
-keepclassmembers class * {
    @androidx.annotation.Keep *;
}
