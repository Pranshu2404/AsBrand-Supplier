# --- FLUTTER ENGINE & PLUGINS ---
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# flutter_secure_storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Keep annotations
-keepattributes *Annotation*
-keepattributes Signature

# Gson (used by various plugins)
-keep class com.google.gson.** { *; }
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Prevent stripping of R classes
-keepclassmembers class **.R$* {
    public static <fields>;
}

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# --- R8 MISSING CLASS FIXES (ANDROID 14 / PLAY CORE) ---
-dontwarn com.google.android.play.core.tasks.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.**