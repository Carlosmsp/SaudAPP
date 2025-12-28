-keepattributes Signature, *Annotation*, EnclosingMethod, InnerClasses
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.google.gson.** { *; }

-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}