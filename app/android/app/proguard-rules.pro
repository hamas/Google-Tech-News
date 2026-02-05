# ProGuard rules for Google Tech News app
# Optimized for Play Store release

#-----------------------------------------------------------------------------
# Flutter Core Rules
#-----------------------------------------------------------------------------
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

#-----------------------------------------------------------------------------
# Isar Database (Local storage)
#-----------------------------------------------------------------------------
-keep class dev.isar.isar.** { *; }
-keep class **.isar.** { *; }
-keepclassmembers class * extends dev.isar.isar.IsarCollection { *; }

#-----------------------------------------------------------------------------
# Firebase Suite
#-----------------------------------------------------------------------------
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Firebase Crashlytics - Keep line numbers for stack trace deobfuscation
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

#-----------------------------------------------------------------------------
# WorkManager (Background Tasks)
#-----------------------------------------------------------------------------
-keep class androidx.work.** { *; }
-keep class * extends androidx.work.Worker
-keep class * extends androidx.work.ListenableWorker
-dontwarn androidx.work.**

#-----------------------------------------------------------------------------
# XML Parsing / RSS
#-----------------------------------------------------------------------------
-keep class org.xmlpull.** { *; }
-keep class com.jamesward.rss.** { *; }
-dontwarn org.xmlpull.**

#-----------------------------------------------------------------------------
# WebView / InAppWebView
#-----------------------------------------------------------------------------
-keepclassmembers class * extends android.webkit.WebViewClient {
    public void *(android.webkit.WebView, java.lang.String, android.graphics.Bitmap);
    public boolean *(android.webkit.WebView, java.lang.String);
    public void *(android.webkit.WebView, java.lang.String);
}
-keepclassmembers class * extends android.webkit.WebChromeClient {
    public void *(android.webkit.WebView, java.lang.String);
}

#-----------------------------------------------------------------------------
# JSON / Serialization (Dio, HTTP)
#-----------------------------------------------------------------------------
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

#-----------------------------------------------------------------------------
# Google Play Core
#-----------------------------------------------------------------------------
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

#-----------------------------------------------------------------------------
# Android Core / Splash
#-----------------------------------------------------------------------------
-keep class androidx.core.splashscreen.** { *; }
-dontwarn androidx.core.splashscreen.**
-keep class androidx.core.** { *; }
-dontwarn androidx.core.**

#-----------------------------------------------------------------------------
# Multidex
#-----------------------------------------------------------------------------
-keep class androidx.multidex.** { *; }

#-----------------------------------------------------------------------------
# Security - Remove debugging/logging in release
#-----------------------------------------------------------------------------
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int d(...);
    public static int i(...);
}

#-----------------------------------------------------------------------------
# Optimization flags
#-----------------------------------------------------------------------------
-optimizationpasses 5
-dontusemixedcaseclassnames
-verbose
-dontpreverify
