plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.yourname.skeleton"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.yourname.skeleton"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val keystorePath = System.getenv("CM_KEYSTORE_PATH")
                ?: error("CM_KEYSTORE_PATH is required for release signing")
            storeFile = file(keystorePath)
            storePassword = System.getenv("CM_KEYSTORE_PASSWORD")
                ?: error("CM_KEYSTORE_PASSWORD is required for release signing")
            keyAlias = System.getenv("CM_KEY_ALIAS")
                ?: error("CM_KEY_ALIAS is required for release signing")
            keyPassword = System.getenv("CM_KEY_PASSWORD")
                ?: error("CM_KEY_PASSWORD is required for release signing")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
