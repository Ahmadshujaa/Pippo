plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.tactics"
    // Audioplayers and its AndroidX dependencies require API 34 or newer.
    // Pinning this avoids a build depending on an older Flutter SDK default.
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    sourceSets {
        getByName("main") {
            jniLibs.srcDirs("src/main/jniLibs")
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.tactics"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        ndk {
            // Ship an engine for every ABI we support. armeabi-v7a is still
            // used by many older Android phones; omitting it makes the app
            // install successfully but leaves Stockfish unavailable.
            abiFilters.add("arm64-v8a")
            abiFilters.add("armeabi-v7a")
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            
            ndk {
                abiFilters.clear()
                abiFilters.add("arm64-v8a")
                abiFilters.add("armeabi-v7a")
            }
        }
    }

    packaging {
        jniLibs {
            // Keep the executable in nativeLibraryDir, where Android permits
            // execution. App-internal files may be mounted noexec.
            useLegacyPackaging = true
            excludes.add("**/libVkLayer_khronos_validation.so")
            // Ensure Stockfish binary is not corrupted by stripping
            keepDebugSymbols.add("**/libstockfish.so")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
