# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Keep R.raw resource identifiers so dynamic lookups succeed
-keepclassmembers class **.R$* {
    public static <fields>;
}
-keep class **.R$raw { *; }
