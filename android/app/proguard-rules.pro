# Flutter standard rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Prevent R8 from removing native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep the sqlite3 classes
-keep class org.sqlite.** { *; }
-keep class sqlite3.** { *; }

# For general plugins that might use reflection
-dontwarn io.flutter.plugins.**
-dontwarn com.omisu.launcher.**

# LibretroDroid JNI reads Java fields by name (GLRetroShader.type, etc.).
# R8 must not rename or strip these or embedded play aborts in LibretroDroid.create().
-keep class com.swordfish.libretrodroid.** { *; }
-keepclassmembers class com.swordfish.libretrodroid.** {
    *;
}

# Fix for missing Play Core classes referenced by Flutter engine
-dontwarn com.google.android.play.core.**

# StreamPack (RTMP / MediaProjection streaming)
-keep class io.github.thibaultbee.streampack.** { *; }
-dontwarn io.github.thibaultbee.streampack.**
