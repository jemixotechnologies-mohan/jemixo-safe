# Flutter engine and embedding.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Native bridge modules are reached through the MethodChannel only.
-keep class com.jemixo.jemixo_safe.** { *; }

# Play Core split-install classes are referenced by Flutter's deferred
# components support but not bundled here.
-dontwarn com.google.android.play.core.**

# ML Kit text recognition: the Flutter plugin references every script's
# recognizer class, but only Latin + Devanagari models are bundled here.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
