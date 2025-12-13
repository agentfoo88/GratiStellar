# Flutter Local Notifications - Preserve generic signatures
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Gson - Keep generic type information
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# Keep all notification-related classes
-keep class androidx.core.app.NotificationCompat** { *; }
-keep class android.app.Notification** { *; }

# Firebase (if needed)
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }