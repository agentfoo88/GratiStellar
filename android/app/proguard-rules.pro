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

# Keep notification icon resources
-keep class **.R$drawable { *; }

# Firebase - Comprehensive rules for Firestore, Auth, Analytics, and Crashlytics
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Firebase Firestore - Keep all classes and methods
-keep class com.google.firebase.firestore.** { *; }
-keep class com.google.firestore.** { *; }
-dontwarn com.google.firebase.firestore.**

# Firebase Auth - Keep all classes and methods
-keep class com.google.firebase.auth.** { *; }
-dontwarn com.google.firebase.auth.**

# Firebase Analytics - Keep all classes and methods
-keep class com.google.firebase.analytics.** { *; }
-keep class com.google.android.gms.measurement.** { *; }
-dontwarn com.google.firebase.analytics.**

# Firebase Crashlytics - Keep all classes and methods
-keep class com.google.firebase.crashlytics.** { *; }
-dontwarn com.google.firebase.crashlytics.**

# Keep Firebase model classes (for serialization)
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Keep native methods for Firebase
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Firebase Parcelable implementations
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep Firebase serialization classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}