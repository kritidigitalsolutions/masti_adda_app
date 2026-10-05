try {
    val pe = Class.forName("java.lang.ProcessEnvironment")
    
    val envField = pe.getDeclaredField("theEnvironment").apply { isAccessible = true }
    (envField.get(null) as? MutableMap<Any, Any>)?.keys?.removeIf { it.toString() == "ANDROID_PREFS_ROOT" }

    val unmodifiableField = pe.getDeclaredField("theUnmodifiableEnvironment").apply { isAccessible = true }
    (unmodifiableField.get(null) as? MutableMap<Any, Any>)?.keys?.removeIf { it.toString() == "ANDROID_PREFS_ROOT" }
} catch (_: Throwable) {}

pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
}

include(":app")
