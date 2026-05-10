# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# ML Kit
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# Speech to Text
-keep class com.csdcorp.speech_to_text.** { *; }

# Hive
-keep class * extends hive.HiveObject { *; }
-keep class hive.** { *; }

# Dio
-keep class dio.** { *; }

# pdf / printing
-keep class com.shockwave.** { *; }

# Tink (для шифрования если будет)
-keep class com.google.crypto.tink.** { *; }
-dontwarn com.google.crypto.tink.**

# Google Play Core (динамические features)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Сохранить аннотации
-keepattributes *Annotation*, InnerClasses, EnclosingMethod, Signature, Exceptions

# Не оптимизировать R8 чересчур агрессивно
-allowaccessmodification
