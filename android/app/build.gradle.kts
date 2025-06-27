plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin") // Flutter plugin
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.abm"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973" // Match required NDK version

    defaultConfig {
        applicationId = "com.example.abm"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true // Required for desugaring
    }

    kotlinOptions {
        jvmTarget = "11"
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.10.1") // Recommended for Kotlin Android
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4") // Required for Java 8+ features
}

flutter {
    source = "../.."
}
