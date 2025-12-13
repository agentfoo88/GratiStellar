plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "grati.stellar.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Enable desugaring
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "grati.stellar.app"
        minSdk = flutter.minSdkVersion  // CHANGED: Firebase requires 21 minimum
        targetSdk = 35  // Set to 35 to match device API level
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true  // CHANGED: = instead of just 'true'
    }

    buildTypes {
        release {
            // Your signing config
            // signingConfig = signingConfigs.getByName("release")

            // Enable minification (Kotlin DSL uses 'is' prefix)
            isMinifyEnabled = true
            isShrinkResources = true

            // ProGuard files
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
}
