# Règles ProGuard/R8 — KingDely Route
# Règles standard Flutter : ne jamais renommer/élaguer les classes du moteur
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

-dontwarn io.flutter.embedding.**
-dontwarn io.flutter.embedding.engine.**
-dontwarn io.flutter.plugin.common.**

# Plugins sensibles à la réflexion : règles de sécurité
-keep class com.momile.livreur_app.** { *; }
-keepclassmembers class * { @android.webkit.JavascriptInterface <methods>; }
