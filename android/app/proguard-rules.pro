# Flutter Proguard Rules
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase Rules
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# SQLite
-keep class com.tekartik.sqflite.** { *; }

# Keep Desugaring classes
-dontwarn java.time.**

# Google Play Core SplitCompat safe suppression
# The app extends standard android.app.Application and does not use Play Feature Delivery / deferred components.
-dontwarn com.google.android.play.core.**