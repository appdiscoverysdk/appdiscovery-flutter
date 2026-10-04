group = "com.appdiscoverysdk.flutter"
version = "1.0.0"

plugins {
    id("com.android.library")
}

// The AppDiscovery Android SDK is served by JitPack. Flutter resolves a plugin's
// dependencies in the app project, so the repository is added to every project.
rootProject.allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://jitpack.io") }
    }
}

android {
    namespace = "com.appdiscoverysdk.flutter"
    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        minSdk = 21
    }
}

dependencies {
    // Neutral native SDK. Keep in sync with scripts/native.env (checked in CI).
    implementation("com.github.appdiscoverysdk:appdiscovery-android:1.0.0")

    // The native SDK exposes Kotlin types (Function1, Unit) in its API.
    implementation("org.jetbrains.kotlin:kotlin-stdlib:1.9.0")
}
