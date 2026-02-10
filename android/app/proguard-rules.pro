# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep generic Flutter classes
-keep class com.google.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }

# Prevent R8 from removing needed classes
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod


# Razorpay rules removed


# Ignore Play Core warnings (ABI splits vs Dynamic Features)
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.android.**
-keep class io.flutter.embedding.android.** { *; }
